import 'package:flutter/material.dart';
import '../../core/app_theme.dart'; // Stil dosyamız

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Ana Sayfa', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Ana Sayfa Dashboard Ekranı',
          style: AppStyles.listTileTitle,
        ),
      ),
    );
  }
}