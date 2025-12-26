// import 'package:flutter/material.dart';
// import '../../core/app_theme.dart'; // Stil dosyamız

// class ShoppingScreen extends StatefulWidget {
//   const ShoppingScreen({super.key});

//   @override
//   State<ShoppingScreen> createState() => _ShoppingScreenState();
// }

// class _ShoppingScreenState extends State<ShoppingScreen> {
//   final List<_ShoppingItem> _items = [];
//   final TextEditingController _controller = TextEditingController();
//   int _seq = 0; // gruplar içinde stabil sıralama için

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _addItem(String name) {
//     final trimmed = name.trim();
//     if (trimmed.isEmpty) return;
//     setState(() {
//       _items.add(
//         _ShoppingItem(
//           id: DateTime.now().microsecondsSinceEpoch,
//           order: _seq++,
//           name: trimmed,
//           done: false,
//         ),
//       );
//       _resort();
//     });
//   }

//   void _toggleById(int id) {
//     final idx = _items.indexWhere((e) => e.id == id);
//     if (idx == -1) return;
//     setState(() {
//       final it = _items[idx];
//       _items[idx] = it.copyWith(done: !it.done);
//       _resort();
//     });
//   }

//   void _deleteById(int id) {
//     setState(() => _items.removeWhere((e) => e.id == id));
//   }

//   // false (alınacak) öğeler üstte, true (alınan) öğeler altta kalır; kendi aralarında eklenme sırasını korur.
//   void _resort() {
//     _items.sort((a, b) {
//       if (a.done != b.done) return a.done ? 1 : -1; // alınacaklar önce
//       return a.order.compareTo(b.order); // grup içi stabil sıra
//     });
//   }

//   Future<void> _showAddItemSheet() async {
//     _controller.clear();
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppStyles.backgroundColor,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             top: 16,
//             bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Ürün Ekle', style: AppStyles.listTileTitle),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _controller,
//                 autofocus: true,
//                 textInputAction: TextInputAction.done,
//                 decoration: const InputDecoration(
//                   hintText: 'Örn: Süt, Ekmek, Yumurta…',
//                   border: OutlineInputBorder(),
//                 ),
//                 onSubmitted: (v) {
//                   _addItem(v);
//                   Navigator.pop(ctx);
//                 },
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     _addItem(_controller.text);
//                     Navigator.pop(ctx);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppStyles.accentColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   icon: const Icon(Icons.add),
//                   label: const Text('Listeye Ekle'),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pending = _items.where((e) => !e.done).toList();
//     final done = _items.where((e) => e.done).toList();

//     // Tek kaydırmalı bir ListView içinde: pending -> çizgi -> done
//     final children = <Widget>[];

//     if (pending.isEmpty && done.isEmpty) {
//       // boş durum
//       children.add(
//         Padding(
//           padding: const EdgeInsets.only(top: 48),
//           child: Center(
//             child: Text(
//               'Listen boş. Sağ alttan ürün ekleyebilirsin.',
//               style: AppStyles.listTileTitle,
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//       );
//     } else {
//       // Alınacaklar (üst kısım)
//       for (final it in pending) {
//         children.add(
//           _ShoppingTile(
//             item: it,
//             onToggle: () => _toggleById(it.id),
//             onDelete: () => _deleteById(it.id),
//             accent: AppStyles.accentColor,
//             crossed: false,
//           ),
//         );
//         children.add(const Divider(height: 1));
//       }

//       // Bölüm çizgisi (tam ortada tek bir çizgi)
//       children.add(const SizedBox(height: 4));
//       children.add(const Divider(thickness: 2));
//       children.add(
//         Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6),
//             child: Text('Alınanlar', style: AppStyles.listTileTitle),
//           ),
//         ),
//       );
//       children.add(const Divider(thickness: 2));
//       children.add(const SizedBox(height: 4));

//       // Alınanlar (alt kısım, tikli + üstü çizili)
//       for (final it in done) {
//         children.add(
//           _ShoppingTile(
//             item: it,
//             onToggle: () => _toggleById(it.id),
//             onDelete: () => _deleteById(it.id),
//             accent: AppStyles.accentColor,
//             crossed: true,
//           ),
//         );
//         children.add(const Divider(height: 1));
//       }
//     }

//     return Scaffold(
//       backgroundColor: AppStyles.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Alışveriş Listesi', style: AppStyles.appBarTitle),
//         backgroundColor: AppStyles.backgroundColor,
//         elevation: 0,
//         actions: [
//           if (_items.isNotEmpty)
//             IconButton(
//               tooltip: 'Tamamlananları sil',
//               onPressed: () {
//                 setState(() => _items.removeWhere((e) => e.done));
//               },
//               icon: const Icon(Icons.delete_sweep),
//             ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         children: children,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddItemSheet,
//         backgroundColor: AppStyles.accentColor,
//         foregroundColor: Colors.white,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

// class _ShoppingTile extends StatelessWidget {
//   final _ShoppingItem item;
//   final VoidCallback onToggle;
//   final VoidCallback onDelete;
//   final Color accent;
//   final bool crossed;

//   const _ShoppingTile({
//     required this.item,
//     required this.onToggle,
//     required this.onDelete,
//     required this.accent,
//     required this.crossed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: ValueKey('item-${item.id}'),
//       direction: DismissDirection.endToStart,
//       background: Container(
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         color: Colors.red.withOpacity(0.85),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       onDismissed: (_) => onDelete(),
//       child: ListTile(
//         onTap: onToggle,
//         leading: Checkbox(
//           value: item.done,
//           activeColor: accent,
//           onChanged: (_) => onToggle(),
//         ),
//         title: Text(
//           item.name,
//           style: AppStyles.listTileTitle.copyWith(
//             decoration: crossed ? TextDecoration.lineThrough : null,
//             color: crossed ? Colors.grey : AppStyles.listTileTitle.color,
//           ),
//         ),
//         trailing: IconButton(
//           tooltip: 'Sil',
//           icon: const Icon(Icons.delete_outline),
//           onPressed: onDelete,
//         ),
//       ),
//     );
//   }
// }

// class _ShoppingItem {
//   final int id; // etkileşimlerde stabil anahtar
//   final int order; // grup içi stabil sıra
//   final String name;
//   final bool done;

//   _ShoppingItem({
//     required this.id,
//     required this.order,
//     required this.name,
//     required this.done,
//   });

//   _ShoppingItem copyWith({int? id, int? order, String? name, bool? done}) {
//     return _ShoppingItem(
//       id: id ?? this.id,
//       order: order ?? this.order,
//       name: name ?? this.name,
//       done: done ?? this.done,
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final List<_ShoppingItem> _items = [];
  final TextEditingController _controller = TextEditingController();
  int _seq = 0;

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

  void _resort() {
    _items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return a.order.compareTo(b.order);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((e) => !e.done).toList();
    final done = _items.where((e) => e.done).toList();
    final double progress = _items.isEmpty ? 0 : done.length / _items.length;

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Mutfak Listesi', style: AppStyles.appBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (done.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _items.removeWhere((e) => e.done)),
              icon: const Icon(Icons.cleaning_services, size: 18, color: AppStyles.accentColor),
              label: const Text('Temizle', style: TextStyle(color: AppStyles.accentColor)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. İlerleme Çubuğu (Alışverişin ne kadarı bitti?)
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Alınan Ürünler', style: AppStyles.listTileSubtitle),
                      Text('${done.length}/${_items.length}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppStyles.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: AppStyles.accentColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _items.isEmpty 
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      const Text('Alınacaklar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...pending.map((it) => _buildShoppingCard(it, false)),
                    ],
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Alınanlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      ...done.map((it) => _buildShoppingCard(it, true)),
                    ],
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        backgroundColor: AppStyles.primaryColor,
        label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _buildShoppingCard(_ShoppingItem it, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(it.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppStyles.deleteColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.delete_sweep, color: Colors.white),
        ),
        onDismissed: (_) => _deleteById(it.id),
        child: Container(
          decoration: BoxDecoration(
            color: isDone ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Checkbox(
              value: it.done,
              activeColor: AppStyles.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => _toggleById(it.id),
            ),
            title: Text(
              it.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : AppStyles.primaryColor,
              ),
            ),
            trailing: isDone 
              ? const Icon(Icons.done_all, color: Colors.green, size: 20)
              : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            onTap: () => _toggleById(it.id),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Text('Listen boş gözüküyor!', style: AppStyles.listTileTitle),
          Text('Hemen bir şeyler ekle.', style: AppStyles.listTileSubtitle),
        ],
      ),
    );
  }

  Future<void> _showAddItemSheet() async {
    _controller.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text('Ne Lazım?', style: AppStyles.popupHeader),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: Yoğurt, 2 adet ekmek...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) { _addItem(v); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () { _addItem(_controller.text); Navigator.pop(ctx); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Listeye Ekle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItem {
  final int id;
  final int order;
  final String name;
  final bool done;
  _ShoppingItem({required this.id, required this.order, required this.name, required this.done});
  _ShoppingItem copyWith({int? id, int? order, String? name, bool? done}) {
    return _ShoppingItem(id: id ?? this.id, order: order ?? this.order, name: name ?? this.name, done: done ?? this.done);
  }
}