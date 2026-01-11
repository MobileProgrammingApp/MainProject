import 'package:flutter/material.dart';
import '../navbars/home.dart';
import '../navbars/chores.dart';
import '../navbars/shopping.dart';
import '../navbars/home_info_screen.dart';
import '../screens/settings_screen.dart';
import 'app_theme.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  // ==========================================
  // ⚙️ NAVİGASYON MANTIĞI (DOKUNMA)
  // Burası sayfa geçişlerini yönetir. Backend değil ama
  // burası bozulursa menü çalışmaz.
  // ==========================================
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  // ==========================================
  // 🏁 MANTIK BİTİŞ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Sayfaları build içinde tanımlıyoruz ki navigasyon fonksiyonunu HomeScreen'e aktarabilelim
    final List<Widget> _pages = [
      HomeScreen(onTabChange: _onItemTapped), 
      const ChoresScreen(),
      const ShoppingScreen(),
      const HomeInfoScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      // 🎨 TASARIM KISMI - BURAYI DÜZENLEYEBİLİRSİN
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyles.accentColor, // Seçili ikon rengi
        unselectedItemColor: Colors.grey,         // Seçili olmayan ikon rengi
        backgroundColor: Colors.white,            // Arka plan rengi
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded), 
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_rounded), 
            label: 'İşler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_rounded), 
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded), 
            label: 'Ev Bilgi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded), 
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}