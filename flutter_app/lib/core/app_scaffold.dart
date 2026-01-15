import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../screens/chores.dart';
import '../screens/shopping.dart';
import '../screens/home_info_screen.dart';
import '../screens/settings_screen.dart';
import 'app_theme.dart';

class AppScaffold extends StatefulWidget {
  final int houseId; 
  const AppScaffold({super.key, required this.houseId});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛠️ DEĞİŞİKLİK: Artık ChoresScreen ve ShoppingScreen'e ID göndermiyoruz.
    // Kendileri hafızadan (SharedPreferences) okuyacaklar.
    // Bu sayede HomeInfoScreen gibi sorunsuz çalışacaklar.
    final List<Widget> _pages = [
      // 🛑 'const' kelimelerini KALDIRIYORUZ ve 'key: UniqueKey()' ekliyoruz
      // Bu sayede her giriş yapıldığında sayfalar sıfırdan üretilir.
      
      HomeScreen(key: UniqueKey(), onTabChange: _onItemTapped), 
      ChoresScreen(key: UniqueKey()), 
      ShoppingScreen(key: UniqueKey()),
      HomeInfoScreen(key: UniqueKey()),
      SettingsScreen(key: UniqueKey()),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyles.accentColor, 
        unselectedItemColor: Colors.grey,         
        backgroundColor: Colors.white,            
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