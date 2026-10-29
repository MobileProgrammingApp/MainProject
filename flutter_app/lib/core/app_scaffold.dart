import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/chores/chores.dart';
import '../features/chores/shopping.dart';
import '../features/home/home_info_screen.dart';
import '../features/settings/settings_screen.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'notification_service.dart';

class AppScaffold extends StatefulWidget {
  final int houseId;
  const AppScaffold({super.key, required this.houseId});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  // Bildirimdeki "screen" verisi -> sekme
  static const _screenTabs = {'home': 0, 'chores': 1, 'shopping': 2};

  int _selectedIndex = 0;
  // "Tekrar dene" açık sayfayı yeniden kurup verisini tekrar çektirir
  int _reloadCount = 0;

  @override
  void initState() {
    super.initState();
    // Uygulama bir bildirime dokunularak açıldıysa doğrudan o sekmeyle başla
    _selectedIndex = _screenTabs[NotificationService.requestedScreen.value] ?? 0;
    NotificationService.requestedScreen.value = null;
    NotificationService.requestedScreen.addListener(_openRequestedScreen);
  }

  @override
  void dispose() {
    NotificationService.requestedScreen.removeListener(_openRequestedScreen);
    super.dispose();
  }

  void _openRequestedScreen() {
    final tab = _screenTabs[NotificationService.requestedScreen.value];
    if (tab == null) return;
    NotificationService.requestedScreen.value = null;
    Navigator.of(context).popUntil((route) => route.isFirst); // açık alt sayfaları kapat
    setState(() {
      _selectedIndex = tab;
      _reloadCount++; // aynı sekmedeyse bile güncel veriyi çeksin
    });
  }

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
        body: KeyedSubtree(
          key: ValueKey('$_selectedIndex-$_reloadCount'),
          child: _buildPage(_selectedIndex),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OfflineBar(onRetry: () => setState(() => _reloadCount++)),
            NavigationBar(
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
          ],
        ),
      ),
    );
  }
}

/// Sunucuya ulaşılamıyorken gezinme çubuğunun üstünde görünen şerit
class _OfflineBar extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBar({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Snackbar gibi: açık temada lacivert üstünde beyaz, koyu temada açık zemin üstünde koyu yazı
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? context.styles.backgroundColor : Colors.white;
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.offline,
      builder: (context, offline, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: !offline
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                color: context.styles.textColor,
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: foreground, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text("İnternet bağlantısı yok",
                          style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(foregroundColor: foreground),
                      child: const Text("Tekrar dene"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
