import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

// ==========================================
// 🎨 TASARIM DOSYASI (TAMAMEN GÜVENLİ)
// Bu dosya sadece ekrandaki görüntüyü oluşturur.
// Backend, API veya sunucu kodu İÇERMEZ.
// Buradaki her şeyi (renkler, yazılar, düzen)
// dilediğin gibi değiştirebilirsin.
// ==========================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: AppStyles.appBarTitle), 
        backgroundColor: AppStyles.backgroundColor
      ),
      body: const Center(
        child: Text('Profil ekranı')
      ),
    );
  }
}