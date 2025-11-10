import 'package:flutter/material.dart';
import 'package:flutter_app/navbars/chores.dart';
import 'package:flutter_app/navbars/home.dart';
import 'package:flutter_app/navbars/home_info_screen.dart';
import 'package:flutter_app/navbars/settings.dart';
import 'package:flutter_app/navbars/shopping.dart';
import 'app_theme.dart'; // Stil dosyamız

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  // 5 adet ekranımızı (sayfamızı) bir listeye koyuyoruz
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HomeInfoScreen(), // Videodaki 'Finans' yerine sizin ekranınız
    ShoppingScreen(),
    ChoresScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Not: Artık ekranların kendi AppBar'ı olduğu için
      // burada genel bir AppBar'a ihtiyacımız yok.
      // body: _widgetOptions.elementAt(_selectedIndex),
      
      // DÜZELTME: Ekranların kendi AppBar'ı olması (özellikle TabBar'lı
      // HomeInfoScreen) kafa karıştırıcı olabilir.
      // DAHA İYİ YÖNTEM: 'IndexedStack' kullanalım.
      // Bu, 5 ekranı da hafızada tutar ve geçişleri hızlı yapar.
      // 'AppBar'ı olmayan bir 'Scaffold' en temizidir.
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        // Bu ayarlar navbar'ın 'eski' görünmesini engeller
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.white,
        
        // Temamızı (Sıcak Turuncu) burada kullanalım
        selectedItemColor: AppStyles.primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_rounded),
            label: 'Ev Bilgileri', // Finans yerine
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Alışveriş',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}