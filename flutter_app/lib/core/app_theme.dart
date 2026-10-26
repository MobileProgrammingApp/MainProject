import 'package:flutter/material.dart';

// ==========================================
// 🎨 TASARIM DOSYASI (TAMAMEN GÜVENLİ)
// Uygulamanın renkleri, yazı stilleri ve bileşen görünümleri burada.
// Renkler HomePal logosundan alındı: çatı mavisi (ana renk), ev turuncusu
// (vurgu/eylem), lacivert (metin). Ekranlarda sabit renk yazmak yerine
// mümkün olduğunca Theme.of(context) ve AppStyles kullanın.
// ==========================================

class AppStyles {
  // Renk Paleti
  static const Color primaryColor = Color(0xFF2563EB); // Logo mavisi
  static const Color accentColor = Color(0xFFF28C28); // Logo turuncusu
  static const Color textColor = Color(0xFF1E2A3B); // Lacivert metin
  static const Color mutedTextColor = Color(0xFF6B7588);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color cardBackgroundColor = Colors.white;
  static const Color borderColor = Color(0xFFE4E8F0);
  static const Color successColor = Color(0xFF2E9D5B);
  static const Color deleteColor = Color(0xFFD64545);

  // Açık tonlar (ikon arka planları, özet kartları)
  static const Color primarySoft = Color(0xFFE6EEFD);
  static const Color accentSoft = Color(0xFFFEF0E2);
  static const Color successSoft = Color(0xFFE3F4EA);

  // Yazı Stilleri
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textColor,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textColor,
  );

  static const TextStyle listTileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle listTileSubtitle = TextStyle(
    fontSize: 14,
    color: mutedTextColor,
  );

  // Kart ve Form Tasarımları
  static const double radius = 16;

  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: const BorderSide(color: borderColor),
  );

  static const double cardElevation = 0;

  static const TextStyle popupHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textColor,
  );

  static final formFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: borderColor),
  );

  static final formFieldFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primaryColor, width: 2),
  );

  /// Beyaz, ince kenarlıklı kart kutusu (Card yerine Container gereken yerler için).
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppStyles.primaryColor,
      primary: AppStyles.primaryColor,
      secondary: AppStyles.accentColor,
      surface: Colors.white,
      error: AppStyles.deleteColor,
    );

    final roundedButton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppStyles.backgroundColor,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: AppStyles.textColor,
        displayColor: AppStyles.textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppStyles.backgroundColor,
        foregroundColor: AppStyles.textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppStyles.textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppStyles.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppStyles.cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppStyles.primarySoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppStyles.primaryColor : AppStyles.mutedTextColor,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppStyles.primaryColor : AppStyles.mutedTextColor,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: roundedButton, padding: buttonPadding),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: roundedButton,
          padding: buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: roundedButton, padding: buttonPadding),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: roundedButton),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: AppStyles.formFieldBorder,
        enabledBorder: AppStyles.formFieldBorder,
        focusedBorder: AppStyles.formFieldFocusedBorder,
        hintStyle: const TextStyle(color: AppStyles.mutedTextColor),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFB8C0CE), width: 1.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppStyles.textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppStyles.borderColor, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: AppStyles.primaryColor),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppStyles.primaryColor),
    );
  }
}
