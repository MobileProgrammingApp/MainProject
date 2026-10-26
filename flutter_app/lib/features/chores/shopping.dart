import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/undo_delete.dart';
import '../../core/widgets/page_header.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final List<_ShoppingItem> _items = [];
  Map<String, String> _memberNames = {}; // "Ekleyen: ..." için üye id -> ad
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Sekmeye her geçişte sayfa yeniden kurulur (AppScaffold), veri burada çekilir.
    _fetchItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI
  // ==========================================

  Future<void> _fetchItems() async {
    final results = await Future.wait([ApiService.getItems(), ApiService.getFamilyMembers(0)]);
    if (!mounted) return;

    setState(() {
      _memberNames = {for (final m in results[1]) m['id'].toString(): m['name'].toString()};
      _items
        ..clear()
        ..addAll(results[0].map((item) => _ShoppingItem(
              id: int.parse(item['id'].toString()),
              name: item['item_name'],
              done: item['is_bought'] == 1 || item['is_bought'] == "1",
              addedBy: _memberNames[item['added_by_member_id']?.toString()],
            )));
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);
    final prefs = await SharedPreferences.getInstance();
    // Ekleyen üye biliniyorsa sunucu ona bildirim göndermez
    final success = await ApiService.addItem(name, prefs.getInt('saved_member_id'));
    if (!mounted) return;

    setState(() => _isAdding = false);
    if (success) {
      _controller.clear();
      _inputFocus.requestFocus(); // Art arda ürün eklemek için klavye açık kalsın
      await _fetchItems();
    } else {
      _showMessage("Eklenemedi");
    }
  }

  // Değişiklik ekrana hemen yansır; sunucu reddederse geri alınır.
  Future<void> _toggle(_ShoppingItem item) async {
    final index = _items.indexOf(item);
    if (index == -1) return;

    final updated = item.copyWith(done: !item.done);
    setState(() => _items[index] = updated);

    final success = await ApiService.setItemBought(item.id, updated.done);
    if (!success && mounted) {
      setState(() {
        final i = _items.indexOf(updated);
        if (i != -1) _items[i] = item;
      });
      _showMessage("Güncellenemedi");
    }
  }

  // Yeni ad ekrana hemen yansır; sunucu reddederse eski ada dönülür.
  Future<void> _rename(_ShoppingItem item, String name) async {
    final index = _items.indexOf(item);
    if (index == -1 || name == item.name) return;

    final updated = item.copyWith(name: name);
    setState(() => _items[index] = updated);

    final success = await ApiService.renameItem(item.id, name);
    if (!success && mounted) {
      setState(() {
        final i = _items.indexOf(updated);
        if (i != -1) _items[i] = item;
      });
      _showMessage("Ürün adı değiştirilemedi");
    }
  }

  Future<void> _showRenameSheet(_ShoppingItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RenameItemSheet(name: item.name, onSave: (name) => _rename(item, name)),
    );
  }

  void _delete(_ShoppingItem item) {
    final index = _items.indexOf(item);
    if (index == -1) return;
    // Kaydırarak silinen öğe hemen listeden çıkmalı (Dismissible bunu bekler)
    setState(() => _items.removeAt(index));

    deleteWithUndo(
      context: context,
      message: "\"${item.name}\" silindi",
      onUndo: () {
        if (mounted) setState(() => _items.insert(index.clamp(0, _items.length), item));
      },
      commit: () => ApiService.deleteItem(item.id),
      onCommitFailed: () {
        if (!mounted) return;
        _showMessage("Silinemedi");
        _fetchItems();
      },
    );
  }

  Future<void> _clearBought() async {
    final bought = _items.where((e) => e.done).toList();
    setState(() => _items.removeWhere((e) => e.done));

    final results = await Future.wait(bought.map((e) => ApiService.deleteItem(e.id)));
    if (results.contains(false) && mounted) {
      _showMessage("Bazı ürünler silinemedi");
      await _fetchItems();
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
    final pending = _items.where((e) => !e.done).toList();
    final done = _items.where((e) => e.done).toList();

    return Scaffold(
      appBar: PageHeader(
        icon: Icons.shopping_basket_rounded,
        title: "Market listesi",
        subtitle: _isLoading
            ? null
            : (ApiService.offline.value && _items.isEmpty)
                ? "Bağlantı yok"
                : _items.isEmpty
                ? "Liste boş"
                : pending.isEmpty
                    ? "Her şey alındı"
                    : "${pending.length} ürün alınacak",
      ),
      body: Column(
        children: [
          _buildAddBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchItems,
                    child: _items.isEmpty && ApiService.offline.value
                        ? const EmptyState.offline()
                        : _items.isEmpty
                        ? const EmptyState(
                            icon: Icons.shopping_basket_outlined,
                            title: "Liste boş",
                            message: "Eksik bir şey olduğunda yukarıdan ekle,\nevdeki herkes görsün.",
                            color: AppStyles.accentColor,
                            softColor: AppStyles.accentSoft,
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              SectionHeader(
                                title: pending.isEmpty ? "Her şey alındı 🎉" : "Alınacaklar",
                                count: pending.length,
                              ),
                              if (pending.isNotEmpty)
                                GroupedCard(dividerIndent: 56, children: pending.map(_buildItemRow).toList()),
                              if (done.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                SectionHeader(
                                  title: "Sepette",
                                  count: done.length,
                                  action: TextButton.icon(
                                    onPressed: _clearBought,
                                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                    label: const Text("Temizle"),
                                    style: TextButton.styleFrom(foregroundColor: AppStyles.mutedTextColor),
                                  ),
                                ),
                                GroupedCard(dividerIndent: 56, children: done.map(_buildItemRow).toList()),
                              ],
                              const ListHint("Adını değiştirmek için ürüne basılı tut"),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _inputFocus,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: "Ne lazım? (örn: süt, ekmek)",
                prefixIcon: Icon(Icons.add_shopping_cart_rounded),
                counterText: "",
              ),
              onSubmitted: (_) => _addItem(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 50,
            width: 50,
            child: FilledButton(
              onPressed: _isAdding ? null : _addItem,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppStyles.accentColor),
              child: _isAdding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(_ShoppingItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppStyles.deleteColor,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(item),
      child: ListTile(
        onTap: () => _toggle(item),
        onLongPress: () => _showRenameSheet(item),
        leading: Checkbox(
          value: item.done,
          activeColor: AppStyles.successColor,
          onChanged: (_) => _toggle(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: item.done ? FontWeight.w400 : FontWeight.w600,
            decoration: item.done ? TextDecoration.lineThrough : null,
            color: item.done ? AppStyles.mutedTextColor : AppStyles.textColor,
          ),
        ),
        subtitle: item.addedBy == null ? null : Text("Ekleyen: ${item.addedBy}"),
        trailing: IconButton(
          tooltip: "Sil",
          icon: const Icon(Icons.close_rounded, size: 20, color: AppStyles.mutedTextColor),
          onPressed: () => _delete(item),
        ),
      ),
    );
  }
}

class _ShoppingItem {
  final int id;
  final String name;
  final bool done;
  final String? addedBy;
  const _ShoppingItem({required this.id, required this.name, required this.done, this.addedBy});

  _ShoppingItem copyWith({String? name, bool? done}) =>
      _ShoppingItem(id: id, name: name ?? this.name, done: done ?? this.done, addedBy: addedBy);
}

class _RenameItemSheet extends StatefulWidget {
  final String name;
  final ValueChanged<String> onSave;

  const _RenameItemSheet({required this.name, required this.onSave});

  @override
  State<_RenameItemSheet> createState() => _RenameItemSheetState();
}

class _RenameItemSheetState extends State<_RenameItemSheet> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context);
    widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Ürünü düzenle", style: AppStyles.popupHeader),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.edit_outlined),
              counterText: "",
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text("Kaydet")),
        ],
      ),
    );
  }
}
