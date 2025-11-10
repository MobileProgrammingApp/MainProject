import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart'; 

// (Not: Bu dosya 'lib/features/home_info/home_info_screen.dart' olarak kaydedilmeli)
// (Önceki kodlardan 'EmptyStateWidget' ve 'InfoTile' gibi alt widget'ları
//  da bu dosyanın en altına ekliyoruz)

class HomeInfoScreen extends StatefulWidget {
  const HomeInfoScreen({super.key});

  @override
  State<HomeInfoScreen> createState() => _HomeInfoScreenState();
}

class _HomeInfoScreenState extends State<HomeInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Map<String, dynamic>> importantInfo = [
    {
      'icon': Icons.wifi,
      'title': 'Wi-Fi Şifresi',
      'value': 'EvdekiHizliInternet123!',
    },
    {
      'icon': Icons.person_outline,
      'title': 'Ev Sahibi Telefon',
      'value': '+90 555 123 4567',
    },
  ];

  final List<Map<String, String>> inventoryItems = [
    {
      'name': 'Kışlık Montlar',
      'location': 'Yatak odası, bazanın altı',
    },
  ];

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

  Future<bool> _showDeleteConfirmationDialog(
      BuildContext context, String itemName) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Silme Onayı'),
          content: Text("'$itemName' öğesini silmek istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700),
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: AppStyles.deleteColor),
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Silme işlemini yapacak ana fonksiyon
  Future<void> _handleDeleteItem(
      BuildContext context, String itemName, int index, String type) async {
    final shouldDelete =
        await _showDeleteConfirmationDialog(context, itemName);

    if (shouldDelete) {
      setState(() {
        if (type == 'info') {
          importantInfo.removeAt(index);
        } else if (type == 'inventory') {
          inventoryItems.removeAt(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bu 'HomeInfoScreen' widget'ı artık bir 'Scaffold' döndürmemeli,
    // çünkü ana 'AppScaffold'un içinde bir 'sayfa' olarak kullanılacak.
    // AppBar ve FAB ana 'AppScaffold'a taşınacak.
    // Bu ekranın sadece 'içeriği' döndürmesi gerekiyor.
    
    // DÜZELTME: Bu ekran, kendi AppBar'ına sahip OLMALI.
    // Çünkü 'Ev Bilgileri' ekranına ÖZEL bir TabBar'ı (iç sekmeleri) var.
    // Bu çok mantıklı. Kodunuzu buna göre düzeltiyorum.
    
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Ev Bilgileri', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0.0,
        // Bu AppBar'ı ana AppBar'ın *altında* göstermek için
        // 'primary: false' ve 'automaticallyImplyLeading: false' ekleyebiliriz
        // veya 'AppScaffold'daki 'AppBar'ı kaldırıp bunu kullanabiliriz.
        // Şimdilik en basit yöntem: Bu, kendi AppBar'ı olan tam bir ekran.
        automaticallyImplyLeading: false, // Geri okunu gösterme
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // ÖNEMLİ BİLGİLER SEKME İÇERİĞİ
          _ImportantInfoTab(
            infoList: importantInfo,
            onItemDelete: (index) async {
              await _handleDeleteItem(
                  context, importantInfo[index]['title'], index, 'info');
            },
          ),
          // EŞYA ENVANTERİ SEKME İÇERİĞİ
          _InventoryTab(
            itemList: inventoryItems,
            onItemDelete: (index) async {
              await _handleDeleteItem(context,
                  inventoryItems[index]['name']!, index, 'inventory');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentTabIndex == 0) {
            _showAddInfoBottomSheet(context);
          } else {
            _showAddItemBottomSheet(context);
          }
        },
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Ekle',
      ),
    );
  }

  // "Önemli Bilgi" ekleme popup'ı
  void _showAddInfoBottomSheet(BuildContext context) {
    _titleController.clear();
    _valueController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Önemli Bilgi Ekle',
                  style: AppStyles.popupHeader),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Başlık (Örn: Kapı Kodu)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Değer (Örn: 1903#)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppStyles.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (_titleController.text.isNotEmpty &&
                        _valueController.text.isNotEmpty) {
                      importantInfo.add({
                        'title': _titleController.text,
                        'value': _valueController.text,
                      });
                      Navigator.pop(context);
                    }
                  });
                },
                child: const Text('Kaydet'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // "Eşya" ekleme popup'ı
  void _showAddItemBottomSheet(BuildContext context) {
    _nameController.clear();
    _locationController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni Eşya Ekle', style: AppStyles.popupHeader),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Eşya Adı (Örn: Yedek Anahtar)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Yeri (Örn: Mutfak, kase içi)',
                  border: AppStyles.formFieldBorder,
                  focusedBorder: AppStyles.formFieldFocusedBorder,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppStyles.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (_nameController.text.isNotEmpty &&
                        _locationController.text.isNotEmpty) {
                      inventoryItems.add({
                        'name': _nameController.text,
                        'location': _locationController.text,
                      });
                      Navigator.pop(context);
                    }
                  });
                },
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
// "LİSTE BOŞ" EKRAN WIDGET'I
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// SEKME 1: ÖNEMLİ BİLGİLER
// -----------------------------------------------------------------
class _ImportantInfoTab extends StatelessWidget {
  final List<Map<String, dynamic>> infoList;
  final Future<void> Function(int) onItemDelete;

  const _ImportantInfoTab(
      {super.key, required this.infoList, required this.onItemDelete});

  @override
  Widget build(BuildContext context) {
    if (infoList.isEmpty) {
      return const _EmptyStateWidget(
        message: 'Henüz bilgi eklenmemiş.\n(+) butonuna basarak ekleyin.',
        icon: Icons.info_outline,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: infoList.length,
      itemBuilder: (context, index) {
        final info = infoList[index];
        return Dismissible(
          key: Key(info['title'] + info['value']),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Silme fonksiyonunu (onaylı) çağır
            await onItemDelete(index);
            // 'false' döndürerek animasyonu iptal et,
            // çünkü 'setState' zaten listeyi güncelledi.
            // (Aslında 'true' da dönebilir, 'setState'e bağlı)
            return false; // 'setState' hallettiği için animasyona gerek yok
          },
          background: Container(
            color: AppStyles.deleteColor,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: _InfoTile(
            icon: info['icon'] as IconData?,
            title: info['title'],
            value: info['value'],
            onDelete: () {
              onItemDelete(index);
            },
          ),
        );
      },
    );
  }
}

// Önemli Bilgiler için Kart Widget'ı
class _InfoTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String value;
  final void Function() onDelete;

  const _InfoTile({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppStyles.cardElevation,
      shadowColor: AppStyles.cardShadowColor,
      shape: AppStyles.cardShape,
      color: AppStyles.cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon ?? Icons.label_important_outline,
            color: AppStyles.primaryColor),
        title: Text(title, style: AppStyles.listTileTitle),
        subtitle: Text(value, style: AppStyles.listTileSubtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.copy_outlined, size: 20, color: Colors.grey),
              tooltip: 'Kopyala',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title kopyalandı: $value'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppStyles.primaryColor,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppStyles.deleteColor),
              tooltip: 'Sil',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// SEKME 2: EŞYA ENVANTERİ
// -----------------------------------------------------------------
class _InventoryTab extends StatelessWidget {
  final List<Map<String, String>> itemList;
  final Future<void> Function(int) onItemDelete;

  const _InventoryTab(
      {super.key, required this.itemList, required this.onItemDelete});

  @override
  Widget build(BuildContext context) {
    if (itemList.isEmpty) {
      return const _EmptyStateWidget(
        message: 'Henüz eşya eklenmemiş.\n(+) butonuna basarak ekleyin.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        final item = itemList[index];
        return Dismissible(
          key: Key(item['name']! + item['location']!),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            await onItemDelete(index);
            return false;
          },
          background: Container(
            color: AppStyles.deleteColor,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Card(
            elevation: AppStyles.cardElevation,
            shadowColor: AppStyles.cardShadowColor,
            shape: AppStyles.cardShape,
            color: AppStyles.cardBackgroundColor,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              title: Text(item['name']!, style: AppStyles.listTileTitle),
              subtitle:
                  Text(item['location']!, style: AppStyles.listTileSubtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppStyles.deleteColor),
                tooltip: 'Sil',
                onPressed: () {
                  onItemDelete(index);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// // -------------------------------------------------------------------
// // --- STİL VE TEMA AYARLARI ---
// // YENİ TEMA: Şık Beyaz & Sıcak Turuncu
// // Sade, modern, "eski uygulama gibi durmayan" bir palet.
// // -------------------------------------------------------------------
// class _AppStyles {
//   // === Ana Renkler ===
//   // Ana Renk (Yazılar, İkonlar, Vurgular) - İstediğin gibi sıcak bir turuncu
//   static const Color primaryColor = Color(0xFFF57C00); // Orange 700
//   // Vurgu Rengi (FAB, Aktif Sekme) - Tamamlayıcı, canlı bir turuncu
//   static const Color accentColor = Color(0xFFFF9800); // Amber 500
//   // Arka Plan Rengi - Sadelik için saf beyaz
//   static const Color backgroundColor = Color(0xFFFFFBF6); // Fildişi/Krem
//   // Kart Arka Planı - Çok hafif kırık beyaz (veya düz beyaz)
//   static const Color cardBackgroundColor = Color(0xFFFFFFFF);
//   // Silme Rengi
//   static const Color deleteColor = Colors.redAccent;

//   // === Kart (Card) Stilleri ===
//   // GÜNCELLEME: "Kutuları" daha şık yapıyoruz.
//   // Artık ağır gölgeler yok. Sadece çok ince bir çerçeve.
//   static const double cardElevation = 2.0; // Çok hafif, havada durma hissi
//   static Color cardShadowColor = Colors.grey.withOpacity(0.15);
//   static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
//     // Kenar yuvarlaklığı
//     borderRadius: BorderRadius.circular(12.0),
//     // GÜNCELLEME: Çok ince, şık çerçeveyi kaldırdık, arka plan rengiyle ayrışacak
//   );

//   // === Yazı Tipi Stilleri ===
//   static const TextStyle appBarTitle = TextStyle(
//     fontWeight: FontWeight.bold,
//     fontSize: 22,
//     color: primaryColor, // Beyaz AppBar üzerinde Turuncu Başlık
//   );
//   static const TextStyle tabLabelStyle = TextStyle(
//     fontWeight: FontWeight.w600,
//     fontSize: 14,
//   );
//   static const TextStyle listTileTitle = TextStyle(
//     fontWeight: FontWeight.w600,
//     fontSize: 16,
//     color: Color(0xFF333333), // Koyu (ama siyah değil) başlık
//   );
//   static const TextStyle listTileSubtitle = TextStyle(
//     fontWeight: FontWeight.normal,
//     fontSize: 14,
//     color: Colors.black54,
//   );
//   static const TextStyle popupHeader = TextStyle(
//     fontWeight: FontWeight.bold,
//     fontSize: 20,
//     color: Color(0xFF333333),
//   );

//   // === Form (TextField) Stilleri ===
//   static final OutlineInputBorder formFieldBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     borderSide: const BorderSide(color: Colors.grey, width: 1.0),
//   );
//   static final OutlineInputBorder formFieldFocusedBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     borderSide: const BorderSide(color: primaryColor, width: 2.0),
//   );
// }
// // --- STİL AYARLARI BİTTİ ---
// // -------------------------------------------------------------------

// class HomeInfoScreen extends StatefulWidget {
//   const HomeInfoScreen({super.key});

//   @override
//   State<HomeInfoScreen> createState() => _HomeInfoScreenState();
// }

// class _HomeInfoScreenState extends State<HomeInfoScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int _currentTabIndex = 0;

//   // Veri listeleri
//   final List<Map<String, dynamic>> importantInfo = [
//     {
//       'icon': Icons.wifi,
//       'title': 'Wi-Fi Şifresi',
//       'value': 'EvdekiHizliInternet123!',
//     },
//     {
//       'icon': Icons.person_outline,
//       'title': 'Ev Sahibi Telefon',
//       'value': '+90 555 123 4567',
//     },
//   ];

//   final List<Map<String, String>> inventoryItems = [
//     {
//       'name': 'Kışlık Montlar',
//       'location': 'Yatak odası, bazanın altı',
//     },
//     {
//       'name': 'Büyük Valiz',
//       'location': 'Koridor, dolabın üstü',
//     },
//   ];

//   // Controller'lar
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _valueController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _tabController.addListener(() {
//       setState(() {
//         _currentTabIndex = _tabController.index;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _titleController.dispose();
//     _valueController.dispose();
//     _nameController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }

//   // "Emin misiniz?" Onay Kutusu
//   Future<bool> _showDeleteConfirmationDialog(
//       BuildContext context, String itemName) async {
//     bool? result = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: const Text('Silme Onayı'),
//           content: Text("'$itemName' öğesini silmek istediğinizden emin misiniz?"),
//           actions: <Widget>[
//             TextButton(
//               style: TextButton.styleFrom(
//                   foregroundColor: Colors.grey.shade700),
//               child: const Text('İptal'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                   foregroundColor: _AppStyles.deleteColor),
//               child: const Text('Sil'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//     return result ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _AppStyles.backgroundColor, // Saf Beyaz
//       // GÜNCELLEME: AppBar artık renkli değil, beyaz. "Eski" hissi vermez.
//       appBar: AppBar(
//         title: const Text('Ev Bilgileri', style: _AppStyles.appBarTitle),
//         backgroundColor: _AppStyles.backgroundColor, // Beyaz AppBar
//         elevation: 0.0, // Gölgesiz, düz tasarım
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: _AppStyles.accentColor, // Turuncu alt çizgi
//           labelColor: _AppStyles.primaryColor, // Seçili sekme (Turuncu)
//           unselectedLabelColor: Colors.grey.shade500, // Seçili olmayan
//           labelStyle: _AppStyles.tabLabelStyle,
//           tabs: const [
//             Tab(icon: Icon(Icons.info_outline), text: 'Önemli Bilgiler'),
//             Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Eşya Envanteri'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // ÖNEMLİ BİLGİLER SEKME İÇERİĞİ
//           _ImportantInfoTab(
//             infoList: importantInfo,
//             // Silme fonksiyonunu callback olarak yolluyoruz
//             onItemDelete: (index) async {
//               // Butona basıldığında...
//               // Önce "Emin misiniz?" diye sor
//               final shouldDelete = await _showDeleteConfirmationDialog(
//                   context, importantInfo[index]['title']);

//               if (shouldDelete) {
//                 setState(() {
//                   importantInfo.removeAt(index);
//                 });
//               }
//             },
//           ),
//           // EŞYA ENVANTERİ SEKME İÇERİĞİ
//           _InventoryTab(
//             itemList: inventoryItems,
//             onItemDelete: (index) async {
//               final shouldDelete = await _showDeleteConfirmationDialog(
//                   context, inventoryItems[index]['name']!);

//               if (shouldDelete) {
//                 setState(() {
//                   inventoryItems.removeAt(index);
//                 });
//               }
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           if (_currentTabIndex == 0) {
//             _showAddInfoBottomSheet(context);
//           } else {
//             _showAddItemBottomSheet(context);
//           }
//         },
//         backgroundColor: _AppStyles.accentColor, // Turuncu FAB
//         foregroundColor: Colors.white,
//         child: const Icon(Icons.add),
//         tooltip: 'Yeni Ekle',
//       ),
//     );
//   }

//   // "Önemli Bilgi" ekleme popup'ı
//   void _showAddInfoBottomSheet(BuildContext context) {
//     _titleController.clear();
//     _valueController.clear();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               top: 20,
//               left: 20,
//               right: 20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Yeni Önemli Bilgi Ekle',
//                   style: _AppStyles.popupHeader),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _titleController,
//                 decoration: InputDecoration(
//                   labelText: 'Başlık (Örn: Kapı Kodu)',
//                   border: _AppStyles.formFieldBorder,
//                   focusedBorder: _AppStyles.formFieldFocusedBorder,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _valueController,
//                 decoration: InputDecoration(
//                   labelText: 'Değer (Örn: 1903#)',
//                   border: _AppStyles.formFieldBorder,
//                   focusedBorder: _AppStyles.formFieldFocusedBorder,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 50),
//                   backgroundColor: _AppStyles.primaryColor, // Turuncu Buton
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     if (_titleController.text.isNotEmpty &&
//                         _valueController.text.isNotEmpty) {
//                       importantInfo.add({
//                         'title': _titleController.text,
//                         'value': _valueController.text,
//                       });
//                       Navigator.pop(context);
//                     }
//                   });
//                 },
//                 child: const Text('Kaydet'),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // "Eşya" ekleme popup'ı
//   void _showAddItemBottomSheet(BuildContext context) {
//     _nameController.clear();
//     _locationController.clear();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               top: 20,
//               left: 20,
//               right: 20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Yeni Eşya Ekle', style: _AppStyles.popupHeader),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Eşya Adı (Örn: Yedek Anahtar)',
//                   border: _AppStyles.formFieldBorder,
//                   focusedBorder: _AppStyles.formFieldFocusedBorder,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _locationController,
//                 decoration: InputDecoration(
//                   labelText: 'Yeri (Örn: Mutfak, kase içi)',
//                   border: _AppStyles.formFieldBorder,
//                   focusedBorder: _AppStyles.formFieldFocusedBorder,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 50),
//                   backgroundColor: _AppStyles.primaryColor, // Turuncu Buton
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     if (_nameController.text.isNotEmpty &&
//                         _locationController.text.isNotEmpty) {
//                       inventoryItems.add({
//                         'name': _nameController.text,
//                         'location': _locationController.text,
//                       });
//                       Navigator.pop(context);
//                     }
//                   });
//                 },
//                 child: const Text('Kaydet'),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // -----------------------------------------------------------------
// // "LİSTE BOŞ" EKRAN WIDGET'I
// // -----------------------------------------------------------------
// class _EmptyStateWidget extends StatelessWidget {
//   final String message;
//   final IconData icon;

//   const _EmptyStateWidget({
//     required this.message,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             size: 80,
//             color: Colors.grey.shade300, // Daha soluk, şık bir ikon
//           ),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade500, // Daha soluk metin
//             ),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }
// }

// // -----------------------------------------------------------------
// // SEKME 1: ÖNEMLİ BİLGİLER
// // -----------------------------------------------------------------
// class _ImportantInfoTab extends StatelessWidget {
//   final List<Map<String, dynamic>> infoList;
//   final Function(int) onItemDelete;

//   const _ImportantInfoTab(
//       {super.key, required this.infoList, required this.onItemDelete});

//   @override
//   Widget build(BuildContext context) {
//     if (infoList.isEmpty) {
//       return const _EmptyStateWidget(
//         message: 'Henüz bilgi eklenmemiş.\n(+) butonuna basarak ekleyin.',
//         icon: Icons.info_outline,
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(12.0),
//       itemCount: infoList.length,
//       itemBuilder: (context, index) {
//         final info = infoList[index];

//         // GÜNCELLEME: HEM KAYDIRMA HEM BUTON
//         // Kartı "Dismissible" (Kaydırılabilir) ile sarıyoruz
//         return Dismissible(
//           // Key, her eleman için benzersiz olmalı
//           key: Key(info['title'] + info['value']),
//           direction: DismissDirection.endToStart, // Sadece sola kaydır
          
//           // Kaydırınca, onay almak için ana fonksiyonu çağır
//           confirmDismiss: (direction) async {
//             return await onItemDelete(index);
//           },
          
//           // Kaydırma arkası
//           background: Container(
//             color: _AppStyles.deleteColor,
//             alignment: Alignment.centerRight,
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             margin: const EdgeInsets.symmetric(vertical: 6.0),
//             child: const Icon(
//               Icons.delete_outline,
//               color: Colors.white,
//             ),
//           ),
          
//           // ASIL KART: _InfoTile (içinde silme butonu da var)
//           child: _InfoTile(
//             icon: info['icon'] as IconData?,
//             title: info['title'],
//             value: info['value'],
//             onDelete: () {
//               // Butona basıldığında da aynı silme fonksiyonunu çağır
//               onItemDelete(index);
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// // Önemli Bilgiler için Kart Widget'ı (Silme Butonu ile)
// class _InfoTile extends StatelessWidget {
//   final IconData? icon;
//   final String title;
//   final String value;
//   final void Function() onDelete;

//   const _InfoTile({
//     super.key,
//     this.icon,
//     required this.title,
//     required this.value,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: _AppStyles.cardElevation,
//       shadowColor: _AppStyles.cardShadowColor,
//       shape: _AppStyles.cardShape, // İnce çerçeveli şık kart
//       color: _AppStyles.cardBackgroundColor,
//       margin: const EdgeInsets.symmetric(vertical: 6.0),
//       child: ListTile(
//         leading: Icon(icon ?? Icons.label_important_outline,
//             color: _AppStyles.primaryColor), // Turuncu İkon
//         title: Text(title, style: _AppStyles.listTileTitle),
//         subtitle: Text(value, style: _AppStyles.listTileSubtitle),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon:
//                   const Icon(Icons.copy_outlined, size: 20, color: Colors.grey),
//               tooltip: 'Kopyala',
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: value));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('$title kopyalandı: $value'),
//                     duration: const Duration(seconds: 1),
//                     backgroundColor: _AppStyles.primaryColor,
//                   ),
//                 );
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete_outline,
//                   color: _AppStyles.deleteColor),
//               tooltip: 'Sil',
//               onPressed: onDelete, // Silme görevini buraya bağla
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // -----------------------------------------------------------------
// // SEKME 2: EŞYA ENVANTERİ
// // -----------------------------------------------------------------
// class _InventoryTab extends StatelessWidget {
//   final List<Map<String, String>> itemList;
//   final Function(int) onItemDelete;

//   const _InventoryTab(
//       {super.key, required this.itemList, required this.onItemDelete});

//   @override
//   Widget build(BuildContext context) {
//     if (itemList.isEmpty) {
//       return const _EmptyStateWidget(
//         message: 'Henüz eşya eklenmemiş.\n(+) butonuna basarak ekleyin.',
//         icon: Icons.inventory_2_outlined,
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(12.0),
//       itemCount: itemList.length,
//       itemBuilder: (context, index) {
//         final item = itemList[index];

//         // GÜNCELLEME: HEM KAYDIRMA HEM BUTON
//         return Dismissible(
//           key: Key(item['name']! + item['location']!),
//           direction: DismissDirection.endToStart,
          
//           confirmDismiss: (direction) async {
//             return await onItemDelete(index);
//           },
          
//           background: Container(
//             color: _AppStyles.deleteColor,
//             alignment: Alignment.centerRight,
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             margin: const EdgeInsets.symmetric(vertical: 6.0),
//             child: const Icon(
//               Icons.delete_outline,
//               color: Colors.white,
//             ),
//           ),
          
//           // ASIL KART (içinde silme butonu da var)
//           child: Card(
//             elevation: _AppStyles.cardElevation,
//             shadowColor: _AppStyles.cardShadowColor,
//             shape: _AppStyles.cardShape, // İnce çerçeveli şık kart
//             color: _AppStyles.cardBackgroundColor,
//             margin: const EdgeInsets.symmetric(vertical: 6.0),
//             child: ListTile(
//               title: Text(item['name']!, style: _AppStyles.listTileTitle),
//               subtitle:
//                   Text(item['location']!, style: _AppStyles.listTileSubtitle),
//               trailing: IconButton(
//                 icon: const Icon(Icons.delete_outline,
//                     color: _AppStyles.deleteColor),
//                 tooltip: 'Sil',
//                 onPressed: () {
//                   onItemDelete(index);
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

