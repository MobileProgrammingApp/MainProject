import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/undo_delete.dart';
import '../../core/widgets/page_header.dart';
import '../home/manage_home_screen.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ
  // ==========================================
  List<_Chore> _chores = [];
  List<dynamic> _houseMembers = [];
  int? _houseId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Sekmeye her geçişte sayfa yeniden kurulur (AppScaffold), veri burada çekilir.
    _loadData();
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
    await Future.wait([_fetchHouseMembers(), _fetchChores()]);
  }

  Future<void> _fetchHouseMembers() async {
    final members = await ApiService.getFamilyMembers(_houseId!);
    if (mounted) setState(() => _houseMembers = members);
  }

  Future<void> _fetchChores() async {
    final data = await ApiService.getChores(_houseId!);
    if (!mounted) return;
    setState(() {
      _chores = data
          .map((c) => _Chore(
                id: int.parse(c['id'].toString()),
                name: c['task_name'].toString(),
                assignedId: c['assigned_to_id'].toString(),
                done: c['is_done'] == 1 || c['is_done'] == "1" || c['is_done'] == true,
              ))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _addChore(String name, String assignedId) async {
    final success = await ApiService.addChore(_houseId!, int.parse(assignedId), name);
    if (!mounted) return;
    if (success) {
      await _fetchChores();
      _showMessage("Görev eklendi");
    } else {
      _showMessage("Görev eklenemedi");
    }
  }

  Future<void> _edit(_Chore chore, String name, String assignedId) async {
    if (name == chore.name && assignedId == chore.assignedId) return;
    final success = await ApiService.editChore(chore.id, name, int.parse(assignedId));
    if (!mounted) return;
    if (success) {
      await _fetchChores();
      _showMessage(assignedId == chore.assignedId ? "Görev güncellendi" : "Görev ${_memberName(assignedId)} kişisine verildi");
    } else {
      _showMessage("Görev güncellenemedi");
    }
  }

  Future<void> _complete(_Chore chore) async {
    final success = await ApiService.completeChore(chore.id);
    if (!mounted) return;
    if (success) {
      await _fetchChores();
      _showMessage("Görev tamamlandı 🎉");
    } else {
      _showMessage("Görev tamamlanamadı");
    }
  }

  void _delete(_Chore chore) {
    final index = _chores.indexOf(chore);
    if (index == -1) return;
    // Kaydırarak silinen öğe hemen listeden çıkmalı (Dismissible bunu bekler)
    setState(() => _chores.removeAt(index));

    deleteWithUndo(
      context: context,
      message: "\"${chore.name}\" silindi",
      onUndo: () {
        if (mounted) setState(() => _chores.insert(index.clamp(0, _chores.length), chore));
      },
      commit: () => ApiService.deleteChore(chore.id),
      onCommitFailed: () {
        if (!mounted) return;
        _showMessage("Görev silinemedi");
        _fetchChores();
      },
    );
  }

  Future<void> _clearDone() async {
    final done = _chores.where((c) => c.done).toList();
    setState(() => _chores.removeWhere((c) => c.done));

    final results = await Future.wait(done.map((c) => ApiService.deleteChore(c.id)));
    if (results.contains(false) && mounted) {
      _showMessage("Bazı görevler silinemedi");
      await _fetchChores();
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _memberName(String id) {
    final member = _houseMembers.firstWhere((m) => m['id'].toString() == id, orElse: () => null);
    return member == null ? "Silinmiş kişi" : member['name'].toString();
  }

  // ==========================================
  // 🎨 TASARIM ALANI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final pending = _chores.where((c) => !c.done).toList();
    final done = _chores.where((c) => c.done).toList();

    return Scaffold(
      appBar: PageHeader(
        icon: Icons.task_alt_rounded,
        title: "Ev işleri",
        subtitle: _isLoading
            ? null
            : (ApiService.offline.value && _chores.isEmpty)
                ? "Bağlantı yok"
                : (pending.isEmpty ? "Bekleyen görev yok" : "${pending.length} görev bekliyor"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "btn_add_chore",
        onPressed: () => _showChoreSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Görev ekle"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _chores.isEmpty && ApiService.offline.value
                  ? const EmptyState.offline()
                  : _chores.isEmpty
                  ? const EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: "Henüz görev yok",
                      message: "Ev işlerini paylaştırmak için\naşağıdan ilk görevi ekle.",
                    )
                  : ListView(
                      // Alttaki "Görev ekle" butonu son satırı kapatmasın
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                      children: [
                        SectionHeader(title: "Bekleyenler", count: pending.length),
                        if (pending.isEmpty)
                          _buildAllDoneCard()
                        else
                          GroupedCard(dividerIndent: 72, children: pending.map(_buildPendingRow).toList()),
                        if (done.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHeader(
                            title: "Tamamlananlar",
                            count: done.length,
                            action: TextButton.icon(
                              onPressed: _clearDone,
                              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                              label: const Text("Temizle"),
                              style: TextButton.styleFrom(foregroundColor: AppStyles.mutedTextColor),
                            ),
                          ),
                          GroupedCard(dividerIndent: 72, children: done.map(_buildDoneRow).toList()),
                        ],
                        if (pending.isNotEmpty) const ListHint("Değiştirmek için göreve dokun"),
                      ],
                    ),
            ),
    );
  }

  Widget _buildAllDoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: const Row(
        children: [
          Icon(Icons.celebration_rounded, color: AppStyles.successColor),
          SizedBox(width: 12),
          Expanded(child: Text("Bütün işler bitti, eline sağlık!", style: AppStyles.listTileTitle)),
        ],
      ),
    );
  }

  Widget _swipeToDelete(_Chore chore, Widget child) {
    return Dismissible(
      key: ValueKey(chore.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppStyles.deleteColor,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(chore),
      child: child,
    );
  }

  Widget _buildPendingRow(_Chore chore) {
    final name = _memberName(chore.assignedId);
    return _swipeToDelete(
      chore,
      ListTile(
        onTap: () => _showChoreSheet(chore),
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        leading: CircleAvatar(
          backgroundColor: AppStyles.primarySoft,
          foregroundColor: AppStyles.primaryColor,
          child: Text(name.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        title: Text(chore.name, style: AppStyles.listTileTitle),
        subtitle: Text(name),
        trailing: IconButton(
          tooltip: "Tamamlandı",
          icon: const Icon(Icons.check_circle_outline_rounded, color: AppStyles.successColor, size: 28),
          onPressed: () => _complete(chore),
        ),
      ),
    );
  }

  Widget _buildDoneRow(_Chore chore) {
    return _swipeToDelete(
      chore,
      ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        leading: const CircleAvatar(
          backgroundColor: AppStyles.successSoft,
          foregroundColor: AppStyles.successColor,
          child: Icon(Icons.check_rounded),
        ),
        title: Text(
          chore.name,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: AppStyles.mutedTextColor,
          ),
        ),
        subtitle: Text("Yapan: ${_memberName(chore.assignedId)}"),
        trailing: IconButton(
          tooltip: "Sil",
          icon: const Icon(Icons.close_rounded, size: 20, color: AppStyles.mutedTextColor),
          onPressed: () => _delete(chore),
        ),
      ),
    );
  }

  /// [chore] verilirse görev düzenlenir, verilmezse yeni görev eklenir.
  Future<void> _showChoreSheet([_Chore? chore]) async {
    await _fetchHouseMembers();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChoreSheet(
        members: _houseMembers,
        initial: chore,
        onSave: chore == null ? _addChore : (name, assignedId) => _edit(chore, name, assignedId),
      ),
    );
  }
}

class _Chore {
  final int id;
  final String name;
  final String assignedId;
  final bool done;
  const _Chore({required this.id, required this.name, required this.assignedId, required this.done});
}

class _ChoreSheet extends StatefulWidget {
  final List<dynamic> members;
  final _Chore? initial;
  final Future<void> Function(String name, String assignedId) onSave;

  const _ChoreSheet({required this.members, required this.onSave, this.initial});

  @override
  State<_ChoreSheet> createState() => _ChoreSheetState();
}

class _ChoreSheetState extends State<_ChoreSheet> {
  late final _nameController = TextEditingController(text: widget.initial?.name);
  String? _assignedId;

  @override
  void initState() {
    super.initState();
    // Görevin sahibi evden silindiyse yeni birini seçmek gerekir
    final id = widget.initial?.assignedId;
    if (widget.members.any((m) => m['id'].toString() == id)) _assignedId = id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _assignedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Görevi yazıp kime atanacağını seçin")),
      );
      return;
    }
    Navigator.pop(context);
    widget.onSave(name, _assignedId!);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(editing ? "Görevi düzenle" : "Yeni görev", style: AppStyles.popupHeader),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            // Düzenlerken klavye hemen açılmasın; çoğu zaman sadece kişi değişir
            autofocus: !editing,
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: "Ne yapılacak? (örn: Çöpleri çıkar)",
              prefixIcon: Icon(Icons.cleaning_services_outlined),
              counterText: "",
            ),
          ),
          const SizedBox(height: 18),
          const Text("Kime atansın?", style: AppStyles.listTileSubtitle),
          const SizedBox(height: 8),
          if (widget.members.isEmpty)
            OutlinedButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute(builder: (_) => const ManageHomeScreen()));
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text("Önce eve bir kişi ekle"),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.members.map<Widget>((m) {
                final id = m['id'].toString();
                return ChoiceChip(
                  label: Text(m['name'].toString()),
                  selected: _assignedId == id,
                  onSelected: (_) => setState(() => _assignedId = id),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: Text(editing ? "Kaydet" : "Görevi ekle")),
        ],
      ),
    );
  }
}
