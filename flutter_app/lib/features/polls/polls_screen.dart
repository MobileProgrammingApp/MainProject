import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';
import 'create_poll_sheet.dart';
import 'poll.dart';
import 'poll_card.dart';

/// Evin bütün anketleri (panelde sadece biri öne çıkar). Panelden açılır.
class PollsScreen extends StatefulWidget {
  /// Profil seçilmeden oy verilmeye çalışılınca Ayarlar sekmesine gitmek için
  final VoidCallback onOpenSettings;

  const PollsScreen({super.key, required this.onOpenSettings});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> with WidgetsBindingObserver {
  // Oylar başka cihazlardan da gelir; panel gibi bu ekran da kendini yeniler
  static const _refreshInterval = Duration(seconds: 20);

  PollsData? _data;
  int? _memberId;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
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
      _load();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('saved_member_id');
    final data = PollsData.fromResponse(await ApiService.getPolls(memberId ?? 0));
    if (!mounted) return;
    setState(() {
      _memberId = memberId;
      // Bağlantı hatasında önceki liste olduğu gibi kalır
      if (data != null) _data = data;
      _isLoading = false;
    });
  }

  String get _summary {
    final polls = _data?.polls ?? const [];
    final open = polls.where((p) => p.isOpen).length;
    final closed = polls.length - open;
    if (polls.isEmpty) return "Ortak kararları oylamayla verin";
    return [if (open > 0) "$open açık", if (closed > 0) "$closed biten"].join(" • ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(icon: Icons.how_to_vote_rounded, title: "Anketler", subtitle: _summary),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreatePollSheet(context, memberId: _memberId, onCreated: _load),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Yeni anket"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _load, child: _buildList()),
    );
  }

  Widget _buildList() {
    final data = _data;
    if (data == null) return const EmptyState.offline();
    if (data.polls.isEmpty) {
      return EmptyState(
        icon: Icons.how_to_vote_rounded,
        title: "Anket yok",
        message: "Ortak kararları oylamayla verin;\naşağıdan yeni bir anket başlat.",
        color: AppStyles.accentColor,
        softColor: context.styles.accentSoft,
      );
    }
    return ListView(
      // FAB son kartın düğmelerini kapatmasın
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
      children: [
        for (final poll in data.polls) ...[
          PollCard(
            key: ValueKey(poll.id),
            poll: poll,
            memberId: _memberId,
            memberCount: data.memberCount,
            onChanged: _load,
            onNeedMember: () {
              Navigator.pop(context);
              widget.onOpenSettings();
            },
          ),
          const SizedBox(height: 12),
        ],
        const ListHint("Biten anketler sonuçlarıyla bir gün görünür, sonra kendiliğinden silinir."),
      ],
    );
  }
}
