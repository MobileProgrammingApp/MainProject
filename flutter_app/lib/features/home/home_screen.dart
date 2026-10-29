import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/widgets/page_header.dart';
import '../polls/create_poll_sheet.dart';
import '../polls/poll.dart';
import '../polls/poll_card.dart';
import '../polls/polls_screen.dart';
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

  // Evin anketleri; panelde biri öne çıkar, hepsi Anketler ekranında.
  // Hiç alınamadıysa (ör. internet yok) null: "anket yok" yerine "alınamadı" gösterilir.
  PollsData? _polls;
  // Sunucudan en az bir kez veri geldi mi? Gelmediyse (ör. internet yok)
  // "0 iş" yerine "alınamadı" gösterilir.
  bool _statsLoaded = false;

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
    final polls = PollsData.fromResponse(await ApiService.getPolls(memberId ?? 0));

    if (!mounted) return;
    setState(() {
      if (stats['status'] == 'success') {
        houseName = stats['house_name'];
        pendingChoresCount = int.parse(stats['pending_chores'].toString());
        pendingShoppingCount = int.parse(stats['pending_items'].toString());
        _statsLoaded = true;
      }
      // Bağlantı/sunucu hatasında önceki anket görünümü olduğu gibi kalır
      if (polls != null) _polls = polls;
      isLoading = false;
    });
  }

  void _openPolls() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PollsScreen(onOpenSettings: () => widget.onTabChange(4))),
    ).then((_) => _loadHomeData(isSilent: true));
  }

  void _newPoll() =>
      showCreatePollSheet(context, memberId: currentMemberId, onCreated: () => _loadHomeData(isSilent: true));

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
                    color: context.styles.primaryColor,
                    softColor: context.styles.primarySoft,
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
                    softColor: context.styles.accentSoft,
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
              title: "Anketler",
              count: (_polls?.polls.length ?? 0) > 0 ? _polls!.polls.length : null,
              action: (_polls?.polls.isNotEmpty ?? false)
                  ? TextButton.icon(
                      onPressed: _newPoll,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("Yeni"),
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
          foregroundColor: context.styles.primaryColor,
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
      // Başlık bandının mavisi: koyu temada da beyaz yazı okunur kalsın
      color: context.styles.headerStart,
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
    final polls = _polls;
    if (isLoading && polls == null) {
      return Container(
        height: 88,
        decoration: context.styles.cardDecoration,
        alignment: Alignment.center,
        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    // Anket bilgisi hiç alınamadıysa (ör. internet yok): "anket yok" demeyelim
    if (polls == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: context.styles.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: context.styles.neutralSoft, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.cloud_off_rounded, color: context.styles.mutedTextColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Anket bilgisi alınamadı", style: context.styles.listTileTitle),
                  const SizedBox(height: 2),
                  Text("Bağlantı gelince kendiliğinden yenilenir.", style: context.styles.listTileSubtitle),
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

    // Anket yoksa: oluşturma kartı
    final featured = polls.featured(currentMemberId);
    if (featured == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: context.styles.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: context.styles.accentSoft, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.how_to_vote_rounded, color: AppStyles.accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Anket yok", style: context.styles.listTileTitle),
                  const SizedBox(height: 2),
                  Text("Ortak kararları oylamayla verin.", style: context.styles.listTileSubtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _newPoll,
              style: FilledButton.styleFrom(backgroundColor: AppStyles.accentColor),
              child: const Text("Oluştur"),
            ),
          ],
        ),
      );
    }

    // Panelde tek anket öne çıkar (önce oyunu bekleyen); diğerleri Anketler ekranında
    final others = polls.polls.length - 1;
    final waiting = currentMemberId == null
        ? 0
        : polls.polls.where((p) => p != featured && p.isOpen && !p.hasVoted).length;
    return Column(
      children: [
        PollCard(
          key: ValueKey(featured.id),
          poll: featured,
          memberId: currentMemberId,
          memberCount: polls.memberCount,
          onChanged: () => _loadHomeData(isSilent: true),
          onNeedMember: () => widget.onTabChange(4),
        ),
        if (others > 0) ...[
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: context.styles.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.how_to_vote_rounded, color: AppStyles.accentColor, size: 22),
              ),
              title: Text("Tüm anketler", style: context.styles.listTileTitle),
              subtitle: Text([
                "$others anket daha",
                if (waiting > 0) "$waiting tanesi oyunu bekliyor",
              ].join(" • ")),
              trailing: Icon(Icons.chevron_right_rounded, color: context.styles.mutedTextColor),
              onTap: _openPolls,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShortcuts() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: Text("Ev üyeleri", style: context.styles.listTileTitle),
            subtitle: const Text("Üye ekle veya çıkar"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHomeScreen())),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: Text("Ev bilgileri", style: context.styles.listTileTitle),
            subtitle: const Text("Wi-Fi, kapı kodu, eşyaların yeri"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => widget.onTabChange(3),
          ),
        ],
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
                  Icon(Icons.arrow_forward_rounded, size: 18, color: context.styles.mutedTextColor),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isLoading || unavailable ? "–" : "$count",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.styles.textColor),
              ),
              Text(!isLoading && unavailable ? unavailableLabel : label, style: context.styles.listTileSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}
