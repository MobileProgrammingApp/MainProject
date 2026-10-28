import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/widgets/page_header.dart';
import 'manage_home_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Anket oyları başka cihazlardan da gelebildiği için panel kendini yeniler.
  // Sadece panel açıkken ve uygulama öndeyken çalışır (bkz. didChangeAppLifecycleState).
  static const _refreshInterval = Duration(seconds: 20);

  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ
  // Buradaki değişkenler sunucudan gelen verileri tutar.
  // ==========================================
  String houseName = "";
  String? memberName;
  int pendingChoresCount = 0;
  int pendingShoppingCount = 0;
  bool isLoading = true;
  Timer? _timer;
  int? currentMemberId;
  int? currentHouseId;

  // Anket Verileri
  String pollQuestion = "";
  List<dynamic> pollOptions = [];
  bool hasActivePoll = false;
  bool hasVoted = false;
  int? activePollId;
  int? votedOptionId;
  // Anket seçilen süre dolunca veya biri bitirince kapanır; sonuç 24 saat daha görünür
  bool pollIsOpen = true;
  int pollMinutesLeft = 0;
  // Açanı belli olan açık anketi sadece o bitirebilir veya yenisiyle değiştirebilir
  int? pollCreatorId;
  String? pollCreatedBy;
  int pollMemberCount = 0;
  bool _pollBusy = false; // oy/bitirme isteği sürerken art arda dokunulmasın
  // Sunucudan en az bir kez veri geldi mi? Gelmediyse (ör. internet yok)
  // "0 iş" / "aktif anket yok" yerine "alınamadı" gösterilir.
  bool _statsLoaded = false;
  bool _pollLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHomeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomeData(isSilent: true);
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI
  // Veri çekme, oy verme ve zamanlayıcı işlemleri.
  // ==========================================

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) _loadHomeData(isSilent: true);
    });
  }

  Future<void> _loadHomeData({bool isSilent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    int? houseId = prefs.getInt('saved_house_id');
    int? memberId = prefs.getInt('saved_member_id');

    if (houseId == null) return;

    currentHouseId = houseId;
    currentMemberId = memberId;

    if (!isSilent && mounted) {
      setState(() {
        isLoading = true;
        houseName = prefs.getString('saved_house_name') ?? "";
        memberName = prefs.getString('saved_member_name');
      });
    }

    final stats = await ApiService.getHomeStats(houseId);
    final pollData = await ApiService.getActivePoll(houseId, memberId ?? 0);

    if (!mounted) return;
    setState(() {
      if (stats['status'] == 'success') {
        houseName = stats['house_name'];
        pendingChoresCount = int.parse(stats['pending_chores'].toString());
        pendingShoppingCount = int.parse(stats['pending_items'].toString());
        _statsLoaded = true;
      }

      if (pollData['status'] == 'success') {
        hasActivePoll = true;
        activePollId = int.parse(pollData['poll_id'].toString());
        pollQuestion = pollData['question'];
        pollOptions = pollData['options'];
        hasVoted = pollData['has_voted'] == true;
        votedOptionId = pollData['voted_option_id'] != null ? int.parse(pollData['voted_option_id'].toString()) : null;
        pollMinutesLeft = int.tryParse('${pollData['minutes_left'] ?? 0}') ?? 0;
        pollIsOpen = pollData['is_open'] != false;
        pollCreatorId = int.tryParse('${pollData['created_by']}');
        pollCreatedBy = pollData['created_by_name'] as String?;
        pollMemberCount = int.tryParse('${pollData['member_count'] ?? 0}') ?? 0;
        _pollLoaded = true;
      } else if (pollData['status'] == 'empty') {
        hasActivePoll = false;
        _pollLoaded = true;
      }
      // Bağlantı/sunucu hatasında önceki anket görünümü olduğu gibi kalır
      isLoading = false;
    });
  }

  Future<void> _handleVote(int optionId) async {
    if (currentMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oy vermek için lütfen Ayarlar'dan kim olduğunuzu seçin.")),
      );
      widget.onTabChange(4);
      return;
    }

    // Anket açıkken oy değiştirilebilir; aynı seçeneğe tekrar dokunmak bir şey yapmaz
    if (!pollIsOpen || optionId == votedOptionId || _pollBusy) return;
    final changing = hasVoted;

    final messenger = ScaffoldMessenger.of(context);
    _pollBusy = true;
    final success = await ApiService.votePoll(activePollId!, optionId, currentHouseId!, currentMemberId!);
    // Başarısızsa anket bu arada bitmiş olabilir: güncel hâli gösterilsin
    await _loadHomeData(isSilent: true);
    _pollBusy = false;

    messenger.showSnackBar(SnackBar(
      content: Text(success ? (changing ? "Oyunuz değiştirildi" : "Oyunuz kaydedildi!") : "Oy kaydedilemedi."),
    ));
  }

  Future<void> _endPoll() async {
    final pollId = activePollId;
    if (pollId == null || _pollBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    _pollBusy = true;
    final success = await ApiService.endPoll(pollId, currentMemberId ?? 0);
    await _loadHomeData(isSilent: true);
    _pollBusy = false;

    messenger.showSnackBar(SnackBar(content: Text(success ? "Anket bitirildi" : "Anket bitirilemedi.")));
  }

  Future<void> _createPoll(String question, List<String> options, int durationHours) async {
    final houseId = currentHouseId;
    if (houseId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.createPoll(houseId, question, options,
        durationHours: durationHours, memberId: currentMemberId);
    if (success) {
      await _loadHomeData(isSilent: true);
      messenger.showSnackBar(const SnackBar(content: Text("Anket oluşturuldu!")));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text("Anket oluşturulurken hata oluştu.")));
    }
  }
  // ==========================================
  // 🏁 BACKEND FONKSİYONLARI BİTİŞ
  // ==========================================

  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // ==========================================

  String get _greeting {
    final hour = DateTime.now().hour;
    final base = hour < 12 ? "Günaydın" : (hour < 18 ? "İyi günler" : "İyi akşamlar");
    return memberName == null ? base : "$base, $memberName";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(
        icon: Icons.home_rounded,
        title: houseName.isEmpty ? "HomePal" : houseName,
        subtitle: _greeting,
        leading: _buildAvatar(),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHomeData(isSilent: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            if (!isLoading && currentMemberId == null) ...[
              _buildMemberPrompt(),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.task_alt_rounded,
                    color: AppStyles.primaryColor,
                    softColor: AppStyles.primarySoft,
                    count: pendingChoresCount,
                    label: "bekleyen iş",
                    unavailableLabel: "görevler alınamadı",
                    isLoading: isLoading,
                    unavailable: !_statsLoaded,
                    onTap: () => widget.onTabChange(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.shopping_basket_rounded,
                    color: AppStyles.accentColor,
                    softColor: AppStyles.accentSoft,
                    count: pendingShoppingCount,
                    label: "alınacak ürün",
                    unavailableLabel: "liste alınamadı",
                    isLoading: isLoading,
                    unavailable: !_statsLoaded,
                    onTap: () => widget.onTabChange(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: "Ev anketi"),
            _buildPollSection(),
            const SizedBox(height: 24),
            const SectionHeader(title: "Kısayollar"),
            _buildShortcuts(),
          ],
        ),
      ),
    );
  }

  // Başlık bandındaki profil rozeti (seçili kişinin baş harfi); dokununca Ayarlar
  Widget _buildAvatar() {
    final initial = (memberName ?? houseName).trim();
    return Tooltip(
      message: "Ayarlar",
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => widget.onTabChange(4),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          foregroundColor: AppStyles.primaryColor,
          child: initial.isEmpty
              ? const Icon(Icons.person_rounded)
              : Text(initial.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // Görev atama, bildirim ve oylama için cihazın hangi üyeye ait olduğu gerekli
  Widget _buildMemberPrompt() {
    return Material(
      color: AppStyles.primaryColor,
      borderRadius: BorderRadius.circular(AppStyles.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onTabChange(4),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sen kimsin?",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text("Bildirim alabilmek ve oy verebilmek için profilini seç.",
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollSection() {
    if (isLoading && !_pollLoaded) {
      return Container(
        height: 88,
        decoration: AppStyles.cardDecoration,
        alignment: Alignment.center,
        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    // Anket bilgisi hiç alınamadıysa (ör. internet yok): "aktif anket yok" demeyelim
    if (!_pollLoaded) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFFEDEFF3), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.cloud_off_rounded, color: AppStyles.mutedTextColor),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Anket bilgisi alınamadı", style: AppStyles.listTileTitle),
                  SizedBox(height: 2),
                  Text("Bağlantı gelince kendiliğinden yenilenir.", style: AppStyles.listTileSubtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _loadHomeData(isSilent: true),
              child: const Text("Tekrar dene"),
            ),
          ],
        ),
      );
    }

    // Aktif anket yoksa: oluşturma kartı
    if (!hasActivePoll) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppStyles.accentSoft, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.how_to_vote_rounded, color: AppStyles.accentColor),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aktif anket yok", style: AppStyles.listTileTitle),
                  SizedBox(height: 2),
                  Text("Ortak kararları oylamayla verin.", style: AppStyles.listTileSubtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _showCreatePollDialog,
              style: FilledButton.styleFrom(backgroundColor: AppStyles.accentColor),
              child: const Text("Oluştur"),
            ),
          ],
        ),
      );
    }

    // Anket varsa: oylama / sonuçlar. Sonuçlar oy verince veya anket bitince görünür.
    final counts = [for (final opt in pollOptions) int.parse(opt['vote_count'].toString())];
    final totalVotes = counts.fold(0, (sum, c) => sum + c);
    final topVotes = counts.fold(0, (top, c) => c > top ? c : top);
    final showResult = hasVoted || !pollIsOpen;

    Widget optionBar(int i) {
      final optionId = int.parse(pollOptions[i]['id'].toString());
      return _PollOptionBar(
        text: pollOptions[i]['option_text'],
        percent: totalVotes == 0 ? 0.0 : counts[i] / totalVotes,
        voteCount: counts[i],
        showResult: showResult,
        isMyChoice: votedOptionId == optionId,
        isWinner: !pollIsOpen && topVotes > 0 && counts[i] == topVotes,
        onTap: pollIsOpen ? () => _handleVote(optionId) : null,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pollQuestion,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppStyles.textColor)),
              ),
              if (!pollIsOpen)
                _pollBadge("Bitti", AppStyles.mutedTextColor, const Color(0xFFEDEFF3))
              else if (hasVoted)
                _pollBadge("Oy verildi", AppStyles.successColor, AppStyles.successSoft),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [if (pollCreatedBy != null) "$pollCreatedBy sordu", pollIsOpen ? _timeLeft : "Anket sona erdi"].join(" • "),
            style: AppStyles.listTileSubtitle,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < pollOptions.length; i++) optionBar(i),
          const SizedBox(height: 2),
          // Herkesin tek oyu olduğu için toplam oy, oy veren kişi sayısıdır
          Text(_pollHint(totalVotes), style: AppStyles.listTileSubtitle),
          if (!pollIsOpen)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _showCreatePollDialog,
                  style: FilledButton.styleFrom(backgroundColor: AppStyles.accentColor),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Yeni anket"),
                ),
              ),
            )
          else if (_canManagePoll)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _confirmEndPoll,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text("Anketi bitir"),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _confirmReplacePoll,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("Yeni anket"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Açık anketi açan kişi (ya da açanı belli değilse herkes) bitirebilir/değiştirebilir;
  // sunucu da aynı kuralı uygular (end_poll.php, create_poll.php)
  bool get _canManagePoll => pollCreatorId == null || pollCreatorId == currentMemberId;

  Widget _pollBadge(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // Seçeneklerin altındaki kısa açıklama: katılım ve ne yapılabileceği
  String _pollHint(int voters) {
    final turnout = voters == 0
        ? (pollIsOpen ? "Henüz oy veren yok" : "Kimse oy vermedi")
        : (pollMemberCount > 0 ? "$voters/$pollMemberCount kişi oy verdi" : "$voters kişi oy verdi");
    if (!pollIsOpen) return turnout;
    final parts = [
      hasVoted ? turnout : "Oy vermek için bir seçeneğe dokunun • $turnout",
      if (hasVoted) "Fikrin değişirse başka seçeneğe dokun",
      if (!_canManagePoll && pollCreatedBy != null) "Anketi $pollCreatedBy bitirebilir",
    ];
    return parts.join(" • ");
  }

  Widget _buildShortcuts() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text("Ev üyeleri", style: AppStyles.listTileTitle),
            subtitle: const Text("Üye ekle veya çıkar"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHomeScreen())),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: const Text("Ev bilgileri", style: AppStyles.listTileTitle),
            subtitle: const Text("Wi-Fi, kapı kodu, eşyaların yeri"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => widget.onTabChange(3),
          ),
        ],
      ),
    );
  }

  String get _timeLeft {
    if (pollMinutesLeft >= 48 * 60) return "${pollMinutesLeft ~/ (24 * 60)} gün kaldı";
    if (pollMinutesLeft >= 60) return "${pollMinutesLeft ~/ 60} saat kaldı";
    if (pollMinutesLeft > 0) return "$pollMinutesLeft dakika kaldı";
    return "kapanmak üzere";
  }

  Future<void> _confirmEndPoll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Anket bitirilsin mi?"),
        content: const Text("Oylama kapanır ve sonuç herkese görünür."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Bitir")),
        ],
      ),
    );
    if (confirmed == true && mounted) _endPoll();
  }

  // Evde tek anket olur; yenisi açılınca açık olan anket ve oyları silinir
  Future<void> _confirmReplacePoll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni anket başlatılsın mı?"),
        content: Text("\"$pollQuestion\" anketi ve verilen oylar silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yeni anket")),
        ],
      ),
    );
    if (confirmed == true && mounted) _showCreatePollDialog();
  }

  // Anket oluşturma penceresi
  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];
    var durationHours = 24;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Yeni anket", style: AppStyles.popupHeader),
                const SizedBox(height: 4),
                const Text("Evdeki herkese bildirim gider; istediğin zaman bitirebilirsin.",
                    style: AppStyles.listTileSubtitle),
                const SizedBox(height: 16),
                TextField(
                  controller: questionCtrl,
                  autofocus: true,
                  maxLength: 255,
                  decoration: const InputDecoration(hintText: "Soru (örn: Bu akşam ne yiyelim?)", counterText: ""),
                ),
                const SizedBox(height: 12),
                ...List.generate(optionCtrls.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: optionCtrls[index],
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: "${index + 1}. seçenek",
                        counterText: "",
                        prefixIcon: const Icon(Icons.radio_button_unchecked, size: 18),
                      ),
                    ),
                  );
                }),
                if (optionCtrls.length < 10)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setSheetState(() => optionCtrls.add(TextEditingController())),
                      icon: const Icon(Icons.add),
                      label: const Text("Seçenek ekle"),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text("Ne kadar açık kalsın?", style: AppStyles.listTileSubtitle),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: durationHours,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppStyles.radius),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.timer_outlined)),
                  items: [
                    for (final entry in _pollDurations.entries)
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  onChanged: (value) => setSheetState(() => durationHours = value ?? durationHours),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    final q = questionCtrl.text.trim();
                    final opts = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                    if (q.isEmpty || opts.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Soru ve en az 2 seçenek girin")),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    _createPoll(q, opts, durationHours);
                  },
                  child: const Text("Anketi başlat"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Anket süresi seçenekleri (saat); sunucu en fazla 1 hafta kabul eder
const _pollDurations = {1: "1 saat", 24: "1 gün", 72: "3 gün", 168: "1 hafta"};

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color softColor;
  final int count;
  final String label;
  final bool isLoading;
  final bool unavailable;
  final String unavailableLabel;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.softColor,
    required this.count,
    required this.label,
    required this.isLoading,
    required this.unavailable,
    required this.unavailableLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: AppStyles.mutedTextColor),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isLoading || unavailable ? "–" : "$count",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppStyles.textColor),
              ),
              Text(!isLoading && unavailable ? unavailableLabel : label, style: AppStyles.listTileSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollOptionBar extends StatelessWidget {
  final String text;
  final double percent;
  final int voteCount;
  final bool showResult;
  final bool isMyChoice;
  final bool isWinner; // biten ankette en çok oyu alan (berabere ise hepsi)
  final VoidCallback? onTap;

  const _PollOptionBar({
    required this.text,
    required this.percent,
    required this.voteCount,
    required this.showResult,
    required this.isMyChoice,
    required this.isWinner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isMyChoice ? AppStyles.primaryColor.withValues(alpha: 0.22) : AppStyles.primaryColor.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Oy oranı çubuğu (kartın genişliğine göre; yatay ekranda da doğru)
              if (showResult)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent,
                    child: AnimatedContainer(duration: const Duration(milliseconds: 400), color: fill),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    if (isWinner) ...[
                      const Icon(Icons.emoji_events_rounded, size: 18, color: AppStyles.accentColor),
                      const SizedBox(width: 8),
                    ],
                    if (isMyChoice) ...[
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppStyles.primaryColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight: isMyChoice || isWinner ? FontWeight.w700 : FontWeight.w500,
                          color: AppStyles.textColor,
                        ),
                      ),
                    ),
                    if (showResult)
                      Text("%${(percent * 100).round()}",
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppStyles.textColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
