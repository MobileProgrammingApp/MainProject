import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_theme.dart';
import '../../core/api_service.dart'; 

class HomeInfoScreen extends StatefulWidget {
  const HomeInfoScreen({super.key});

  @override
  State<HomeInfoScreen> createState() => _HomeInfoScreenState();
}

class _HomeInfoScreenState extends State<HomeInfoScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ (DOKUNMA)
  // Bu değişkenler verileri hafızada tutar.
  // ==========================================
  int? currentUserId;
  List<dynamic> importantInfo = [];
  List<dynamic> inventoryItems = [];
  bool isLoading = true;

  // Form Kontrolcüleri (Veri girişi için teknik araçlar)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadData(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _valueController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI (DOKUNMA)
  // Sunucuyla konuşan, kayıt yapan ve silen kodlar.
  // Tasarımla ilgisi yoktur.
  // ==========================================

  // 1. Verileri Çek
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('saved_house_id');
    });

    if (currentUserId != null) {
      final data = await ApiService.getHomeDetails(currentUserId!);
      if (data['status'] == 'success') {
        setState(() {
          importantInfo = data['infos'];
          inventoryItems = data['inventory'];
          isLoading = false;
        });
      }
    }
  }

  // 2. Yeni Bilgi Ekle (API)
  Future<void> _addNewInfo() async {
    if (currentUserId == null) return;
    bool success = await ApiService.addInfo(
      currentUserId!,
      _titleController.text,
      _valueController.text
    );
    if (success) {
      _loadData();
      if(mounted) Navigator.pop(context);
    }
  }

  // 3. Yeni Eşya Ekle (API)
  Future<void> _addNewInventory() async {
    if (currentUserId == null) return;
    bool success = await ApiService.addInventory(
      currentUserId!,
      _nameController.text,
      _locationController.text
    );
    if (success) {
      _loadData();
      if(mounted) Navigator.pop(context);
    }
  }

  // 4. Silme İşlemi (API)
  Future<void> _handleDeleteItem(BuildContext context, int id, String type) async {
    // Onay Kutusu (Tasarım kısmı aşağıda ama mantığı burada)
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Silme Onayı'),
          content: const Text("Bu öğeyi silmek istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      bool success = false;
      if (type == 'info') {
        success = await ApiService.deleteInfo(id);
      } else {
        success = await ApiService.deleteInventory(id);
      }

      if (success) {
        _loadData();
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silindi")));
        }
      }
    }
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI BAŞLANGIÇ
  // Buradan aşağısı ekran görüntüsüyle ilgilidir.
  // Renkleri, buton şekillerini, yazıları değiştirebilirsin.
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Ev Bilgileri', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.accentColor,
          labelColor: AppStyles.primaryColor,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: AppStyles.tabLabelStyle,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Önemli Bilgiler'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Eşya Envanteri'),
          ],
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
            controller: _tabController,
            children: [
              // SEKME 1: BİLGİLER LİSTESİ
              _ImportantInfoTab(
                infoList: importantInfo, // Backend verisi gönderiliyor
                onItemDelete: (id) => _handleDeleteItem(context, id, 'info'), // Silme fonksiyonu
              ),
              // SEKME 2: ENVANTER LİSTESİ
              _InventoryTab(
                itemList: inventoryItems, // Backend verisi gönderiliyor
                onItemDelete: (id) => _handleDeleteItem(context, id, 'inventory'), // Silme fonksiyonu
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_info_screen",
        onPressed: () {
          if (_currentTabIndex == 0) {
            _showAddInfoBottomSheet(context);
          } else {
            _showAddItemBottomSheet(context);
          }
        },
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        tooltip: 'Yeni Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- POP-UP PENCERESİ TASARIMI (BİLGİ EKLEME) ---
  void _showAddInfoBottomSheet(BuildContext context) {
    _titleController.clear();
    _valueController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Önemli Bilgi Ekle', style: AppStyles.popupHeader),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Başlık (Örn: Wi-Fi)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Değer (Örn: sifre123)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppStyles.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addNewInfo, // Backend fonksiyonunu çağırır
                child: const Text('Kaydet'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- POP-UP PENCERESİ TASARIMI (EŞYA EKLEME) ---
  void _showAddItemBottomSheet(BuildContext context) {
    _nameController.clear();
    _locationController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Eşya Ekle', style: AppStyles.popupHeader),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Eşya Adı (Örn: Pasaportlar)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Yeri (Örn: Kasa içi)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppStyles.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addNewInventory, // Backend fonksiyonunu çağırır
                child: const Text('Kaydet'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------
// 🎨 YARDIMCI WIDGETLAR (Tasarım Bileşenleri)
// -----------------------------------------------------------------

class _EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyStateWidget({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ImportantInfoTab extends StatelessWidget {
  final List<dynamic> infoList;
  final Function(int) onItemDelete;

  const _ImportantInfoTab({required this.infoList, required this.onItemDelete});

  // Burası tasarım mantığıdır. Kelimeye göre ikon seçer.
  // Arkadaşın buraya yeni kelimeler ekleyebilir.
  IconData _getIconForTitle(String title) {
    title = title.toLowerCase();
    if (title.contains('wifi') || title.contains('internet') || title.contains('modem')) return Icons.wifi;
    if (title.contains('tel') || title.contains('numara') || title.contains('iletişim')) return Icons.phone;
    if (title.contains('şifre') || title.contains('kod') || title.contains('pin')) return Icons.password;
    if (title.contains('su') || title.contains('vana')) return Icons.water_drop;
    if (title.contains('elektrik') || title.contains('sigorta')) return Icons.flash_on;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (infoList.isEmpty) {
      return const _EmptyStateWidget(message: 'Henüz bilgi eklenmemiş.\n(+) ile ekleyin.', icon: Icons.info_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: infoList.length,
      itemBuilder: (context, index) {
        final info = infoList[index];
        final int id = int.parse(info['id'].toString());
        
        return _InfoTile(
          icon: _getIconForTitle(info['title']),
          title: info['title'],
          value: info['value'],
          onDelete: () => onItemDelete(id),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onDelete;

  const _InfoTile({required this.icon, required this.title, required this.value, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppStyles.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopyalandı'), duration: Duration(seconds: 1)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  final List<dynamic> itemList;
  final Function(int) onItemDelete;

  const _InventoryTab({required this.itemList, required this.onItemDelete});

  @override
  Widget build(BuildContext context) {
    if (itemList.isEmpty) {
      return const _EmptyStateWidget(message: 'Henüz eşya eklenmemiş.\n(+) ile ekleyin.', icon: Icons.inventory_2_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        final item = itemList[index];
        final int id = int.parse(item['id'].toString());

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.orange),
            title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['location']),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => onItemDelete(id),
            ),
          ),
        );
      },
    );
  }
}