import 'package:flutter/material.dart';
import '../../core/app_theme.dart'; // Stil dosyamız

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Alışveriş Listesi', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Alışveriş Listesi Ekranı',
          style: AppStyles.listTileTitle,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}