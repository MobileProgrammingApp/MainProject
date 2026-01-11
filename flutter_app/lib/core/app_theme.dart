import 'package:flutter/material.dart';

// ==========================================
// 🎨 TASARIM DOSYASI (TAMAMEN GÜVENLİ)
// Bu dosya uygulamanın genel renklerini ve yazı tiplerini içerir.
// Backend kodu yoktur. Tasarımı değiştirmek için buradaki renkleri
// ve font boyutlarını dilediğin gibi değiştirebilirsin.
// ==========================================

class AppStyles {
  // Renk Paleti
  static const Color primaryColor = Color(0xFF2C3E50); // Lacivert tonu
  static const Color accentColor = Color(0xFFE67E22);  // Turuncu (Sıcaklık katar)
  static const Color backgroundColor = Color(0xFFFDFEFE);
  static const Color cardBackgroundColor = Colors.white;
  static const Color deleteColor = Colors.redAccent;

  // Yazı Stilleri
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle listTileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle listTileSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // Kart ve Form Tasarımları
  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  );
  
  static const double cardElevation = 2.0;
  
  static const TextStyle popupHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static final formFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static final formFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: accentColor, width: 2),
  );

  static Color? get cardShadowColor => null;

  static TextStyle? get tabLabelStyle => null;
}