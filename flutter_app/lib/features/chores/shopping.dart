import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});
  
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final List<_ShoppingItem> _items = [];
  final TextEditingController _controller = TextEditingController();
  
  int? _currentHouseId; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // didChangeDependencies içinde çağrılacak
  }

  // --- DÜZELTME: Sayfa her odaklandığında çalışır ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Verileri ve Kimliği Hafızadan Taze Çek
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔥 ÖNEMLİ: Hafızayı tazele (Eski kullanıcının verisi kalmasın)
    await prefs.reload();
    // Önce temizle
    if (mounted) {
      setState(() {
        _items.clear();
        _isLoading = true;
      });
    }

    int? savedId = prefs.getInt('saved_house_id');

    if (savedId != null) {
      if (mounted) {
        setState(() {
          _currentHouseId = savedId;
        });
      }
      await _fetchItems();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchItems() async {
    if (_currentHouseId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';
      final response = await http.get(Uri.parse("https://homepal.swordarchitecture.com/get_items.php?user_id=$_currentHouseId&api_token=$token"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _items.clear();
            for (var item in data) {
              bool isDone = (item['is_bought'] == 1 || item['is_bought'] == "1");

              _items.add(_ShoppingItem(
                id: int.parse(item['id'].toString()),
                name: item['item_name'],
                done: isDone,
                order: 0,
              ));
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
    }
  }

  Future<void> _addItem(String name) async {
    if (_currentHouseId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';
      final response = await http.post(
        Uri.parse("https://homepal.swordarchitecture.com/add_item.php"),
        body: {
          "api_token": token,
          "user_id": _currentHouseId.toString(),
          "item_name": name,
        },
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        if (result['status'] == 'success') {
          await _fetchItems(); 
        }
      }
    } catch (e) {
      print("Ekleme hatası: $e");
    }
  }

  Future<void> _toggleById(int id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final bool currentStatus = _items[idx].done;
    final String nextStatus = currentStatus ? "0" : "1";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';
      final response = await http.post(
        Uri.parse("https://homepal.swordarchitecture.com/update_item.php"),
        body: {
          "api_token": token,
          "id": id.toString(),
          "is_bought": nextStatus,
        },
      );

      if (response.statusCode == 200 && json.decode(response.body)['status'] == 'success') {
        await _fetchItems();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Güncellenemedi")),
        );
      }
    } catch (e) {
      print("Güncelleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bağlantı hatası")),
        );
      }
    }
  }

  Future<void> _deleteById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';
      final response = await http.post(
        Uri.parse("https://homepal.swordarchitecture.com/delete_item.php"),
        body: {"api_token": token, "id": id.toString()},
      );
      if (response.statusCode == 200 && json.decode(response.body)['status'] == 'success') {
        _fetchItems();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silinemedi")),
        );
      }
    } catch (e) {
      print("Silme hatası: $e");
    }
  }

  // ==========================================
  // 🎨 TASARIM ALANI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((e) => !e.done).toList();
    final done = _items.where((e) => e.done).toList();
    
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor, 
      
      appBar: AppBar(
        title: const Text('🛒 Market Listesi'), 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.shopping_basket, color: Colors.green, size: 16),
                label: Text('${done.length}/${_items.length} Ürün', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.shade50,
              ),
            ),
          ),
          if (done.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services, color: AppStyles.accentColor),
              tooltip: "Alınanları Temizle",
              onPressed: () async {
                for (var item in done) {
                  await _deleteById(item.id); 
                }
              },
            ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_shopping_item",
        onPressed: _showAddItemSheet,
        backgroundColor: AppStyles.primaryColor,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData, // Çek bırak yenile
            child: _items.isEmpty 
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text(
                        'Alınacaklar', 
                        style: Theme.of(context).textTheme.headlineSmall, 
                      ),
                      const SizedBox(height: 10),
                      ...pending.map((it) => _buildShoppingCard(it, false)),
                    ],

                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      Text(
                        'Sepete Atılanlar', 
                        style: Theme.of(context).textTheme.headlineSmall, 
                      ),
                      const SizedBox(height: 10),
                      ...done.map((it) => _buildShoppingCard(it, true)),
                    ],
                  ],
                ),
        ),
    );
  }

  Widget _buildShoppingCard(_ShoppingItem it, bool isDone) {
    return Card(
      elevation: 2, 
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(it.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppStyles.deleteColor,
            borderRadius: BorderRadius.circular(12), 
          ),
          child: const Icon(Icons.delete_sweep, color: Colors.white),
        ),
        onDismissed: (direction) {
          _deleteById(it.id); 
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Checkbox(
            value: it.done,
            activeColor: Colors.green, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              _toggleById(it.id); 
            },
          ),
          title: Text(
            it.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.grey : Colors.black87,
            ),
          ),
          trailing: isDone 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
          onTap: () {
            _toggleById(it.id); 
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade200),
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
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
             Text(
              '➕ Ne Lazım?', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı (Örn: Süt, Ekmek)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              onSubmitted: (v) { _addItem(v); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Listeye Ekle', style: TextStyle(fontSize: 16)),
              onPressed: () { _addItem(_controller.text); Navigator.pop(ctx); },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
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
}