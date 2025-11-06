import 'package:flutter/material.dart';

// -------------------------------------------------------------------
// --- STİL VE TEMA AYARLARI ---
// YENİ TEMA: Şık Beyaz & Sıcak Turuncu
// -------------------------------------------------------------------
class AppStyles {
  // === Ana Renkler ===
  static const Color primaryColor = Color(0xFFF57C00); // Orange 700
  static const Color accentColor = Color(0xFFFF9800); // Amber 500
  static const Color backgroundColor = Color(0xFFFFFBF6); // Fildişi/Krem
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);
  static const Color deleteColor = Colors.redAccent;

  // === Kart (Card) Stilleri ===
  static const double cardElevation = 2.0;
  static Color cardShadowColor = Colors.grey.withOpacity(0.15);
  static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
  );

  // === Yazı Tipi Stilleri ===
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 22,
    color: primaryColor,
  );
  static const TextStyle tabLabelStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  static const TextStyle listTileTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Color(0xFF333333),
  );
  static const TextStyle listTileSubtitle = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: Colors.black54,
  );
  static const TextStyle popupHeader = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: Color(0xFF333333),
  );

  // === Form (TextField) Stilleri ===
  static final OutlineInputBorder formFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
  );
  static final OutlineInputBorder formFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primaryColor, width: 2.0),
  );
}