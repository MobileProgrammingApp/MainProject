import 'package:flutter/material.dart';

class AppStyles {
  // Renk Paleti
  static const Color primaryColor = Color(0xFF2C3E50); // Lacivert tonu
  static const Color accentColor = Color(0xFFE67E22);  // Turuncu (Sıcaklık katar)
  static const Color backgroundColor = Color(0xFFFDFEFE); // [cite: 113, 115]
  static const Color cardBackgroundColor = Colors.white; // [cite: 97, 108]
  static const Color deleteColor = Colors.redAccent; // [cite: 45, 91, 101]

  // Yazı Stilleri
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  ); // [cite: 52, 113, 144, 172]

  static const TextStyle listTileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  ); // [cite: 97, 109, 114, 127, 175]

  static const TextStyle listTileSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  ); // [cite: 98, 109]

  // Kart ve Form Tasarımları
  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ); // [cite: 97, 108]
  
  static const double cardElevation = 2.0; // [cite: 97, 108]
  
  static const TextStyle popupHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ); // [cite: 62, 73]

  static final formFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  ); // [cite: 63, 74]

  static final formFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: accentColor, width: 2),
  );

  static Color? get cardShadowColor => null;

  static TextStyle? get tabLabelStyle => null; // [cite: 63, 74, 76]
}
// import 'package:flutter/material.dart';

// // -------------------------------------------------------------------
// // --- STİL VE TEMA AYARLARI ---
// // YENİ TEMA: Şık Beyaz & Sıcak Turuncu
// // -------------------------------------------------------------------
// class AppStyles {
//   // === Ana Renkler ===
//   static const Color primaryColor = Color(0xFFF57C00); // Orange 700
//   static const Color accentColor = Color(0xFFFF9800); // Amber 500
//   static const Color backgroundColor = Color(0xFFFFFBF6); // Fildişi/Krem
//   static const Color cardBackgroundColor = Color(0xFFFFFFFF);
//   static const Color deleteColor = Colors.redAccent;

//   // === Kart (Card) Stilleri ===
//   static const double cardElevation = 2.0;
//   static Color cardShadowColor = Colors.grey.withOpacity(0.15);
//   static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(12.0),
//   );

//   // === Yazı Tipi Stilleri ===
//   static const TextStyle appBarTitle = TextStyle(
//     fontWeight: FontWeight.bold,
//     fontSize: 22,
//     color: primaryColor,
//   );
//   static const TextStyle tabLabelStyle = TextStyle(
//     fontWeight: FontWeight.w600,
//     fontSize: 14,
//   );
//   static const TextStyle listTileTitle = TextStyle(
//     fontWeight: FontWeight.w600,
//     fontSize: 16,
//     color: Color(0xFF333333),
//   );
//   static const TextStyle listTileSubtitle = TextStyle(
//     fontWeight: FontWeight.normal,
//     fontSize: 14,
//     color: Colors.black54,
//   );
//   static const TextStyle popupHeader = TextStyle(
//     fontWeight: FontWeight.bold,
//     fontSize: 20,
//     color: Color(0xFF333333),
//   );

//   // === Form (TextField) Stilleri ===
//   static final OutlineInputBorder formFieldBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     borderSide: const BorderSide(color: Colors.grey, width: 1.0),
//   );
//   static final OutlineInputBorder formFieldFocusedBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     borderSide: const BorderSide(color: primaryColor, width: 2.0),
//   );
// }