import 'package:flutter/material.dart';
import '../../core/app_theme.dart'; // Stil dosyamız

class ChoresScreen extends StatelessWidget {
  const ChoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Görevler', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Görevler Ekranı',
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