import 'package:flutter/material.dart';
import '../../core/app_theme.dart'; // Stil dosyamız

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final List<_ShoppingItem> _items = [];
  final TextEditingController _controller = TextEditingController();
  int _seq = 0; // gruplar içinde stabil sıralama için

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _items.add(
        _ShoppingItem(
          id: DateTime.now().microsecondsSinceEpoch,
          order: _seq++,
          name: trimmed,
          done: false,
        ),
      );
      _resort();
    });
  }

  void _toggleById(int id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    setState(() {
      final it = _items[idx];
      _items[idx] = it.copyWith(done: !it.done);
      _resort();
    });
  }

  void _deleteById(int id) {
    setState(() => _items.removeWhere((e) => e.id == id));
  }

  // false (alınacak) öğeler üstte, true (alınan) öğeler altta kalır; kendi aralarında eklenme sırasını korur.
  void _resort() {
    _items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1; // alınacaklar önce
      return a.order.compareTo(b.order); // grup içi stabil sıra
    });
  }

  Future<void> _showAddItemSheet() async {
    _controller.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyles.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ürün Ekle', style: AppStyles.listTileTitle),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Örn: Süt, Ekmek, Yumurta…',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) {
                  _addItem(v);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _addItem(_controller.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.accentColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Listeye Ekle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((e) => !e.done).toList();
    final done = _items.where((e) => e.done).toList();

    // Tek kaydırmalı bir ListView içinde: pending -> çizgi -> done
    final children = <Widget>[];

    if (pending.isEmpty && done.isEmpty) {
      // boş durum
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Center(
            child: Text(
              'Listen boş. Sağ alttan ürün ekleyebilirsin.',
              style: AppStyles.listTileTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Alınacaklar (üst kısım)
      for (final it in pending) {
        children.add(
          _ShoppingTile(
            item: it,
            onToggle: () => _toggleById(it.id),
            onDelete: () => _deleteById(it.id),
            accent: AppStyles.accentColor,
            crossed: false,
          ),
        );
        children.add(const Divider(height: 1));
      }

      // Bölüm çizgisi (tam ortada tek bir çizgi)
      children.add(const SizedBox(height: 4));
      children.add(const Divider(thickness: 2));
      children.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Alınanlar', style: AppStyles.listTileTitle),
          ),
        ),
      );
      children.add(const Divider(thickness: 2));
      children.add(const SizedBox(height: 4));

      // Alınanlar (alt kısım, tikli + üstü çizili)
      for (final it in done) {
        children.add(
          _ShoppingTile(
            item: it,
            onToggle: () => _toggleById(it.id),
            onDelete: () => _deleteById(it.id),
            accent: AppStyles.accentColor,
            crossed: true,
          ),
        );
        children.add(const Divider(height: 1));
      }
    }

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Alışveriş Listesi', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Tamamlananları sil',
              onPressed: () {
                setState(() => _items.removeWhere((e) => e.done));
              },
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: children,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  final _ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Color accent;
  final bool crossed;

  const _ShoppingTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.accent,
    required this.crossed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('item-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.withOpacity(0.85),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onToggle,
        leading: Checkbox(
          value: item.done,
          activeColor: accent,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.name,
          style: AppStyles.listTileTitle.copyWith(
            decoration: crossed ? TextDecoration.lineThrough : null,
            color: crossed ? Colors.grey : AppStyles.listTileTitle.color,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Sil',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _ShoppingItem {
  final int id; // etkileşimlerde stabil anahtar
  final int order; // grup içi stabil sıra
  final String name;
  final bool done;

  _ShoppingItem({
    required this.id,
    required this.order,
    required this.name,
    required this.done,
  });

  _ShoppingItem copyWith({int? id, int? order, String? name, bool? done}) {
    return _ShoppingItem(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      done: done ?? this.done,
    );
  }
}
