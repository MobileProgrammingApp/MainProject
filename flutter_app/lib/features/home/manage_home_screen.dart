import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';

class ManageHomeScreen extends StatefulWidget {
  const ManageHomeScreen({super.key});

  @override
  State<ManageHomeScreen> createState() => _ManageHomeScreenState();
}

class _ManageHomeScreenState extends State<ManageHomeScreen> {
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ
  // ==========================================
  int? _houseId;
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI
  // ==========================================

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _houseId = prefs.getInt('saved_house_id');
    if (_houseId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final data = await ApiService.getFamilyMembers(_houseId!);
    if (!mounted) return;
    setState(() {
      _members = data;
      _isLoading = false;
    });
  }

  /// Ekleme formundan çağrılır; başarılıysa true döner (form kapanır).
  Future<bool> _add(String name) async {
    final success = await ApiService.addFamilyMember(_houseId!, name);
    if (!mounted) return success;
    if (success) {
      await _load();
      _showMessage("$name eklendi");
    } else {
      _showMessage("Kişi eklenemedi");
    }
    return success;
  }

  Future<void> _delete(String name, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$name silinsin mi?"),
        content: const Text("Bu kişiye atanmış görevler ve verdiği oylar da silinir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.styles.deleteColor),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ApiService.deleteFamilyMember(id);
    if (!mounted) return;
    if (success) {
      await _load();
      _showMessage("$name silindi");
    } else {
      _showMessage("Silme başarısız oldu");
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ==========================================
  // 🎨 TASARIM ALANI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(
        icon: Icons.people_alt_rounded,
        title: "Ev üyeleri",
        subtitle: _isLoading
            ? null
            : (ApiService.offline.value && _members.isEmpty)
                ? "Bağlantı yok"
                : (_members.isEmpty ? "Henüz kimse yok" : "${_members.length} kişi"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "btn_add_member",
        onPressed: _showAddSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Kişi ekle"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _members.isEmpty && ApiService.offline.value
                  ? const EmptyState.offline()
                  : _members.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_alt_outlined,
                      title: "Henüz kimse eklenmemiş",
                      message: "Evde yaşayanları ekle; görevler ve\nanketler bu kişilerle çalışır.",
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                      children: [
                        GroupedCard(
                          dividerIndent: 72,
                          children: _members.map((member) {
                            final name = member['name'].toString();
                            return ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                              leading: CircleAvatar(
                                backgroundColor: context.styles.primarySoft,
                                foregroundColor: context.styles.primaryColor,
                                child: Text(name.characters.first.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              title: Text(name, style: context.styles.listTileTitle),
                              trailing: IconButton(
                                tooltip: "Sil",
                                icon: Icon(Icons.close_rounded, size: 20, color: context.styles.mutedTextColor),
                                onPressed: () => _delete(name, int.parse(member['id'].toString())),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMemberSheet(onAdd: _add),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final Future<bool> Function(String name) onAdd;
  const _AddMemberSheet({required this.onAdd});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final ok = await widget.onAdd(name);
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
          Text("Yeni kişi", style: context.styles.popupHeader),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: "İsim (örn: Ayşe)",
              prefixIcon: Icon(Icons.person_outline_rounded),
              counterText: "",
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Ekle"),
          ),
        ],
      ),
    );
  }
}
