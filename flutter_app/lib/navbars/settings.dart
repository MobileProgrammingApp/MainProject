
import 'package:flutter/material.dart';
import '../../core/app_theme.dart'; // Stil dosyamız

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Ayarlar', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppStyles.primaryColor),
              title: const Text('Profil', style: AppStyles.listTileTitle),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.home_work, color: AppStyles.primaryColor),
              title: const Text('Evi Yönet', style: AppStyles.listTileTitle),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppStyles.primaryColor),
              title: const Text('Çıkış Yap', style: AppStyles.listTileTitle),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}