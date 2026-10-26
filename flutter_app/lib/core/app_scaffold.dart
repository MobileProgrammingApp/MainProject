import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/chores/chores.dart';
import '../features/chores/shopping.dart';
import '../features/home/home_info_screen.dart';
import '../features/settings/settings_screen.dart';

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

  // Sadece seçili sekme oluşturulur. Sekmeye her geçişte sayfa yeniden
  // kurulup güncel veriyi çeker; diğer sekmeler arka planda istek atmaz.
  Widget _buildPage(int index) {
    switch (index) {
      case 1:
        return const ChoresScreen();
      case 2:
        return const ShoppingScreen();
      case 3:
        return const HomeInfoScreen();
      case 4:
        return const SettingsScreen();
      default:
        return HomeScreen(onTabChange: _onItemTapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: KeyedSubtree(key: ValueKey(_selectedIndex), child: _buildPage(_selectedIndex)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt_rounded),
              label: 'İşler',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_basket_outlined),
              selectedIcon: Icon(Icons.shopping_basket_rounded),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ev Bilgi',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
