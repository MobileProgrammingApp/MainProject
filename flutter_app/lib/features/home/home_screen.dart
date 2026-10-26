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
  int pollMinutesLeft = 0; // anket 24 saat sonra kapanır (sunucu siler)
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

    if (hasVoted) return;

    bool success = await ApiService.votePoll(activePollId!, optionId, currentHouseId!, currentMemberId!);
    if (!mounted) return;

    if (success) {
      await _loadHomeData(isSilent: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oyunuz kaydedildi!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oy kaydedilemedi.")));
    }
  }

  Future<void> _createPoll(String question, List<String> options) async {
    final houseId = currentHouseId;
    if (houseId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.createPoll(houseId, question, options);
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
            SectionHeader(
              title: "Ev anketi",
              action: hasActivePoll
                  ? TextButton.icon(
                      onPressed: _confirmReplacePoll,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("Yeni anket"),
                    )
                  : null,
            ),
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

    // Aktif anket varsa: oylama / sonuçlar
    int totalVotes = 0;
    for (var opt in pollOptions) {
      totalVotes += int.parse(opt['vote_count'].toString());
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
              if (hasVoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppStyles.successSoft, borderRadius: BorderRadius.circular(20)),
                  child: const Text("Oy verildi",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppStyles.successColor)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${hasVoted ? "$totalVotes oy kullanıldı" : "Oy vermek için bir seçeneğe dokunun"} • $_timeLeft",
            style: AppStyles.listTileSubtitle,
          ),
          const SizedBox(height: 16),
          ...pollOptions.map((option) {
            final voteCount = int.parse(option['vote_count'].toString());
            final optionId = int.parse(option['id'].toString());
            final percent = totalVotes == 0 ? 0.0 : voteCount / totalVotes;
            return _PollOptionBar(
              text: option['option_text'],
              percent: percent,
              voteCount: voteCount,
              showResult: hasVoted,
              isMyChoice: votedOptionId == optionId,
              onTap: hasVoted ? null : () => _handleVote(optionId),
            );
          }),
        ],
      ),
    );
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

  // Anket oluşturma penceresi
  String get _timeLeft {
    if (pollMinutesLeft >= 60) return "${pollMinutesLeft ~/ 60} saat sonra kapanır";
    if (pollMinutesLeft > 0) return "$pollMinutesLeft dakika sonra kapanır";
    return "kapanmak üzere";
  }

  // Evde tek aktif anket olur; yenisi açılınca eskisi ve oyları silinir
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

  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];

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
                const Text("Anket 24 saat açık kalır; evdeki herkese bildirim gider.", style: AppStyles.listTileSubtitle),
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
                const SizedBox(height: 8),
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
                    _createPoll(q, opts);
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
  final VoidCallback? onTap;

  const _PollOptionBar({
    required this.text,
    required this.percent,
    required this.voteCount,
    required this.showResult,
    required this.isMyChoice,
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
                    if (isMyChoice) ...[
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppStyles.primaryColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight: isMyChoice ? FontWeight.w700 : FontWeight.w500,
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
