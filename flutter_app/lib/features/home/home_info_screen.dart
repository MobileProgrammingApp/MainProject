import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';

class HomeInfoScreen extends StatefulWidget {
  const HomeInfoScreen({super.key});

  @override
  State<HomeInfoScreen> createState() => _HomeInfoScreenState();
}

class _HomeInfoScreenState extends State<HomeInfoScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ
  // ==========================================
  int? _houseId;
  List<dynamic> _infos = [];
  List<dynamic> _inventory = [];
  bool _isLoading = true;
  final Set<int> _revealed = {}; // gösterilen gizli bilgiler (şifre, kod...)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI
  // ==========================================

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _houseId = prefs.getInt('saved_house_id');
    if (_houseId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final data = await ApiService.getHomeDetails(_houseId!);
    if (!mounted) return;
    setState(() {
      if (data['status'] == 'success') {
        _infos = data['infos'];
        _inventory = data['inventory'];
      }
      _isLoading = false;
    });
  }

  /// Ekleme formundan çağrılır; başarılıysa true döner (form kapanır).
  Future<bool> _add(bool isInfo, String first, String second) async {
    final success = isInfo
        ? await ApiService.addInfo(_houseId!, first, second)
        : await ApiService.addInventory(_houseId!, first, second);
    if (!mounted) return success;

    if (success) {
      await _loadData();
    } else {
      _showMessage("Kaydedilemedi, lütfen tekrar deneyin");
    }
    return success;
  }

  Future<void> _delete(int id, bool isInfo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text("Bu kayıt evdeki herkes için silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.styles.deleteColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = isInfo ? await ApiService.deleteInfo(id) : await ApiService.deleteInventory(id);
    if (!mounted) return;
    if (success) {
      await _loadData();
      _showMessage("Silindi");
    } else {
      _showMessage("Silinemedi");
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ==========================================
  // 🎨 TASARIM ALANI
  // ==========================================

  bool get _onInfoTab => _tabController.index == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(
        icon: Icons.home_rounded,
        title: "Ev bilgileri",
        subtitle: _isLoading
            ? null
            : (ApiService.offline.value && _infos.isEmpty && _inventory.isEmpty)
                ? "Bağlantı yok"
                : "${_infos.length} bilgi • ${_inventory.length} eşya",
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(height: 48, text: 'Önemli bilgiler'),
            Tab(height: 48, text: 'Eşyaların yeri'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "btn_add_info_screen",
        onPressed: () => _showAddSheet(isInfo: _onInfoTab),
        icon: const Icon(Icons.add_rounded),
        label: Text(_onInfoTab ? "Bilgi ekle" : "Eşya ekle"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(onRefresh: _loadData, child: _buildInfoList()),
                RefreshIndicator(onRefresh: _loadData, child: _buildInventoryList()),
              ],
            ),
    );
  }

  // Başlıktaki kelimeye göre ikon seçer
  IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('wifi') || t.contains('wi-fi') || t.contains('internet') || t.contains('modem')) return Icons.wifi_rounded;
    if (t.contains('tel') || t.contains('numara') || t.contains('iletişim')) return Icons.phone_rounded;
    if (t.contains('şifre') || t.contains('kod') || t.contains('pin')) return Icons.password_rounded;
    if (t.contains('su ') || t == 'su' || t.contains('vana')) return Icons.water_drop_rounded;
    if (t.contains('elektrik') || t.contains('sigorta')) return Icons.bolt_rounded;
    if (t.contains('doğalgaz') || t.contains('kombi')) return Icons.local_fire_department_rounded;
    return Icons.info_outline_rounded;
  }

  // Şifre, kod gibi bilgiler telefon başkasına gösterilirken görünmesin
  bool _isSecret(String title) {
    final t = title.toLowerCase();
    return ['şifre', 'sifre', 'parola', 'kod', 'pin', 'wifi', 'wi-fi', 'password'].any(t.contains);
  }

  Widget _buildInfoList() {
    if (_infos.isEmpty && ApiService.offline.value) return const EmptyState.offline();
    if (_infos.isEmpty) {
      return const EmptyState(
        icon: Icons.info_outline_rounded,
        title: "Henüz bilgi yok",
        message: "Wi-Fi şifresi, kapı kodu, önemli numaralar…\nHerkesin bilmesi gerekenleri buraya ekle.",
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
      children: [
        GroupedCard(
          dividerIndent: 72,
          children: _infos.map((info) {
            final value = info['value'].toString();
            final id = int.parse(info['id'].toString());
            final hidden = _isSecret(info['title'].toString()) && !_revealed.contains(id);
            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              leading: _iconBadge(_iconForTitle(info['title'].toString()), context.styles.primaryColor, context.styles.primarySoft),
              title: Text(info['title'].toString(), style: context.styles.listTileSubtitle),
              subtitle: Text(hidden ? "••••••••" : value, style: context.styles.listTileTitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSecret(info['title'].toString()))
                    IconButton(
                      tooltip: hidden ? "Göster" : "Gizle",
                      icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: context.styles.primaryColor),
                      onPressed: () => setState(() => hidden ? _revealed.add(id) : _revealed.remove(id)),
                    ),
                  IconButton(
                    tooltip: "Kopyala",
                    icon: Icon(Icons.copy_rounded, size: 20, color: context.styles.primaryColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kopyalandı'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: "Sil",
                    icon: Icon(Icons.close_rounded, size: 20, color: context.styles.mutedTextColor),
                    onPressed: () => _delete(id, true),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    if (_inventory.isEmpty && ApiService.offline.value) return const EmptyState.offline();
    if (_inventory.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: "Henüz eşya yok",
        message: "Pasaportlar, yedek anahtar, faturalar…\nNerede olduklarını unutmamak için ekle.",
        color: AppStyles.accentColor,
        softColor: context.styles.accentSoft,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
      children: [
        GroupedCard(
          dividerIndent: 72,
          children: _inventory.map((item) {
            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              leading: _iconBadge(Icons.inventory_2_rounded, AppStyles.accentColor, context.styles.accentSoft),
              title: Text(item['item_name'].toString(), style: context.styles.listTileTitle),
              subtitle: Row(
                children: [
                  Icon(Icons.place_outlined, size: 15, color: context.styles.mutedTextColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text(item['location'].toString())),
                ],
              ),
              trailing: IconButton(
                tooltip: "Sil",
                icon: Icon(Icons.close_rounded, size: 20, color: context.styles.mutedTextColor),
                onPressed: () => _delete(int.parse(item['id'].toString()), false),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _iconBadge(IconData icon, Color color, Color soft) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _showAddSheet({required bool isInfo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddEntrySheet(
        title: isInfo ? "Yeni bilgi" : "Yeni eşya",
        firstHint: isInfo ? "Başlık (örn: Wi-Fi şifresi)" : "Eşya (örn: Pasaportlar)",
        firstIcon: isInfo ? Icons.label_outline_rounded : Icons.inventory_2_outlined,
        firstMax: 100,
        secondHint: isInfo ? "Bilgi (örn: ev12345)" : "Yeri (örn: Kasanın içi)",
        secondIcon: isInfo ? Icons.notes_rounded : Icons.place_outlined,
        secondMax: 255,
        onSave: (first, second) => _add(isInfo, first, second),
      ),
    );
  }
}

/// İki alanlı ekleme formu (bilgi: başlık + değer, eşya: ad + yer)
class _AddEntrySheet extends StatefulWidget {
  final String title;
  final String firstHint;
  final IconData firstIcon;
  final int firstMax;
  final String secondHint;
  final IconData secondIcon;
  final int secondMax;
  final Future<bool> Function(String first, String second) onSave;

  const _AddEntrySheet({
    required this.title,
    required this.firstHint,
    required this.firstIcon,
    required this.firstMax,
    required this.secondHint,
    required this.secondIcon,
    required this.secondMax,
    required this.onSave,
  });

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _first.text.trim();
    final second = _second.text.trim();
    if (first.isEmpty || second.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen iki alanı da doldurun")));
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave(first, second);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: context.styles.popupHeader),
          const SizedBox(height: 16),
          TextField(
            controller: _first,
            autofocus: true,
            maxLength: widget.firstMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: widget.firstHint, prefixIcon: Icon(widget.firstIcon), counterText: ""),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _second,
            maxLength: widget.secondMax,
            decoration: InputDecoration(hintText: widget.secondHint, prefixIcon: Icon(widget.secondIcon), counterText: ""),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
