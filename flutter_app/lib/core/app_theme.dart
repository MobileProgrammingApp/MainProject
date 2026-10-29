import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 🎨 TASARIM DOSYASI (TAMAMEN GÜVENLİ)
// Uygulamanın renkleri, yazı stilleri ve bileşen görünümleri burada.
// Renkler HomePal logosundan alındı: çatı mavisi (ana renk), ev turuncusu
// (vurgu/eylem), lacivert (metin). Açık ve koyu tema var: temaya göre değişen
// renk ve stiller context.styles ile alınır (ör. context.styles.textColor),
// iki temada aynı kalanlar doğrudan AppStyles üzerindedir (ör. AppStyles.accentColor).
// Ekranlarda sabit renk yazmak yerine bunları ve Theme.of(context) kullanın.
// ==========================================

class AppStyles extends ThemeExtension<AppStyles> {
  // İki temada da aynı kalan renkler
  static const Color brandBlue = Color(0xFF2563EB); // Logo mavisi (amblemde)
  static const Color brandNavy = Color(0xFF1E2A3B); // Logo laciverti (amblemin yüzü)
  static const Color accentColor = Color(0xFFF28C28); // Logo turuncusu
  static const Color successColor = Color(0xFF2E9D5B);

  static const double radius = 16;

  // Temaya göre değişen renkler
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color backgroundColor;
  final Color cardBackgroundColor;
  final Color borderColor;
  final Color deleteColor;

  // Açık tonlar (ikon arka planları, özet kartları, rozetler)
  final Color primarySoft;
  final Color accentSoft;
  final Color successSoft;
  final Color deleteSoft;
  final Color neutralSoft;

  // Anket seçeneği gibi oran çubuklarının zemini
  final Color trackColor;

  // Sayfa başlığı bandının (PageHeader) renk geçişi
  final Color headerStart;
  final Color headerEnd;

  const AppStyles({
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.backgroundColor,
    required this.cardBackgroundColor,
    required this.borderColor,
    required this.deleteColor,
    required this.primarySoft,
    required this.accentSoft,
    required this.successSoft,
    required this.deleteSoft,
    required this.neutralSoft,
    required this.trackColor,
    required this.headerStart,
    required this.headerEnd,
  });

  static const light = AppStyles(
    primaryColor: brandBlue,
    textColor: brandNavy,
    mutedTextColor: Color(0xFF6B7588),
    backgroundColor: Color(0xFFF5F7FB),
    cardBackgroundColor: Colors.white,
    borderColor: Color(0xFFE4E8F0),
    deleteColor: Color(0xFFD64545),
    primarySoft: Color(0xFFE6EEFD),
    accentSoft: Color(0xFFFEF0E2),
    successSoft: Color(0xFFE3F4EA),
    deleteSoft: Color(0xFFFBE6E6),
    neutralSoft: Color(0xFFEDEFF3),
    trackColor: Color(0xFFF1F4F9),
    headerStart: brandBlue,
    headerEnd: Color(0xFF1D4ED8),
  );

  // Koyu zeminde okunabilsin diye mavi ve kırmızı biraz açıldı
  static const dark = AppStyles(
    primaryColor: Color(0xFF4F86F7),
    textColor: Color(0xFFE7EBF3),
    mutedTextColor: Color(0xFF98A2B5),
    backgroundColor: Color(0xFF0F141E),
    cardBackgroundColor: Color(0xFF192131),
    borderColor: Color(0xFF283245),
    deleteColor: Color(0xFFEF6B6B),
    primarySoft: Color(0xFF1D2B48),
    accentSoft: Color(0xFF3B2A19),
    successSoft: Color(0xFF18352A),
    deleteSoft: Color(0xFF3D2024),
    neutralSoft: Color(0xFF252E3E),
    trackColor: Color(0xFF212A3A),
    headerStart: Color(0xFF1D46B8),
    headerEnd: Color(0xFF17388F),
  );

  // Yazı Stilleri
  TextStyle get sectionTitle => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  TextStyle get listTileTitle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  TextStyle get listTileSubtitle => TextStyle(
        fontSize: 14,
        color: mutedTextColor,
      );

  TextStyle get popupHeader => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  // Kart ve Form Tasarımları
  RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor),
      );

  OutlineInputBorder get formFieldBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      );

  OutlineInputBorder get formFieldFocusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      );

  /// İnce kenarlıklı kart kutusu (Card yerine Container gereken yerler için).
  BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      );

  @override
  AppStyles copyWith({
    Color? primaryColor,
    Color? textColor,
    Color? mutedTextColor,
    Color? backgroundColor,
    Color? cardBackgroundColor,
    Color? borderColor,
    Color? deleteColor,
    Color? primarySoft,
    Color? accentSoft,
    Color? successSoft,
    Color? deleteSoft,
    Color? neutralSoft,
    Color? trackColor,
    Color? headerStart,
    Color? headerEnd,
  }) {
    return AppStyles(
      primaryColor: primaryColor ?? this.primaryColor,
      textColor: textColor ?? this.textColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      deleteColor: deleteColor ?? this.deleteColor,
      primarySoft: primarySoft ?? this.primarySoft,
      accentSoft: accentSoft ?? this.accentSoft,
      successSoft: successSoft ?? this.successSoft,
      deleteSoft: deleteSoft ?? this.deleteSoft,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      trackColor: trackColor ?? this.trackColor,
      headerStart: headerStart ?? this.headerStart,
      headerEnd: headerEnd ?? this.headerEnd,
    );
  }

  // Tema değişirken renkler yumuşak geçsin
  @override
  AppStyles lerp(AppStyles? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppStyles(
      primaryColor: mix(primaryColor, other.primaryColor),
      textColor: mix(textColor, other.textColor),
      mutedTextColor: mix(mutedTextColor, other.mutedTextColor),
      backgroundColor: mix(backgroundColor, other.backgroundColor),
      cardBackgroundColor: mix(cardBackgroundColor, other.cardBackgroundColor),
      borderColor: mix(borderColor, other.borderColor),
      deleteColor: mix(deleteColor, other.deleteColor),
      primarySoft: mix(primarySoft, other.primarySoft),
      accentSoft: mix(accentSoft, other.accentSoft),
      successSoft: mix(successSoft, other.successSoft),
      deleteSoft: mix(deleteSoft, other.deleteSoft),
      neutralSoft: mix(neutralSoft, other.neutralSoft),
      trackColor: mix(trackColor, other.trackColor),
      headerStart: mix(headerStart, other.headerStart),
      headerEnd: mix(headerEnd, other.headerEnd),
    );
  }
}

extension AppStylesContext on BuildContext {
  /// Etkin temanın (açık/koyu) renkleri ve stilleri. Theme.of üzerinden
  /// okunduğu için tema değişince kullanan widget'lar yeniden çizilir.
  AppStyles get styles => Theme.of(this).extension<AppStyles>()!;
}

class AppTheme {
  /// Ayarlar'da seçilen tema bu anahtarla saklanır (oturum kapanınca silinmez).
  static const modeKey = 'theme_mode';

  /// MaterialApp bunu dinler. Varsayılan: telefonun ayarına uy.
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  // Seçim Android'e de bildirilir: Android 12+ açılış ekranı uygulamanın temasıyla
  // çizilsin (bkz. MainActivity.kt). Diğer platformlarda karşılığı yok, hata yutulur.
  static const _platform = MethodChannel('homepal/theme');

  static Future<void> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = ThemeMode.values.asNameMap()[prefs.getString(modeKey)] ?? ThemeMode.system;
    // Her açılışta eşitlenir: uygulama verisi silinse de sistemdeki seçim eski kalmasın.
    // Beklenmez, ilk kare gecikmesin.
    unawaited(_applyToPlatform(mode.value));
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(modeKey, value.name);
    await _applyToPlatform(value);
  }

  static Future<void> _applyToPlatform(ThemeMode value) async {
    try {
      await _platform.invokeMethod('setNightMode', value.name);
    } catch (e) {
      debugPrint("Tema sisteme bildirilemedi: $e");
    }
  }

  static ThemeData get light => _build(
        AppStyles.light,
        ColorScheme.fromSeed(
          seedColor: AppStyles.brandBlue,
          primary: AppStyles.light.primaryColor,
          secondary: AppStyles.accentColor,
          surface: AppStyles.light.cardBackgroundColor,
          error: AppStyles.light.deleteColor,
        ),
      );

  static ThemeData get dark => _build(
        AppStyles.dark,
        ColorScheme.fromSeed(
          seedColor: AppStyles.brandBlue,
          brightness: Brightness.dark,
          primary: AppStyles.dark.primaryColor,
          onPrimary: Colors.white,
          secondary: AppStyles.accentColor,
          surface: AppStyles.dark.cardBackgroundColor,
          onSurface: AppStyles.dark.textColor,
          onSurfaceVariant: AppStyles.dark.mutedTextColor,
          error: AppStyles.dark.deleteColor,
        ),
      );

  static ThemeData _build(AppStyles s, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final roundedButton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [s],
      scaffoldBackgroundColor: s.backgroundColor,
      textTheme: (isDark ? Typography.whiteMountainView : Typography.blackMountainView).apply(
        bodyColor: s.textColor,
        displayColor: s.textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: s.backgroundColor,
        foregroundColor: s.textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: s.textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: s.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: s.cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: s.primarySoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? s.primaryColor : s.mutedTextColor,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? s.primaryColor : s.mutedTextColor,
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
          backgroundColor: s.primaryColor,
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
        fillColor: s.cardBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: s.formFieldBorder,
        enabledBorder: s.formFieldBorder,
        focusedBorder: s.formFieldFocusedBorder,
        hintStyle: TextStyle(color: s.mutedTextColor),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: isDark ? const Color(0xFF5A6478) : const Color(0xFFB8C0CE), width: 1.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Koyu temada açık renkli olur (metin rengi), zeminden ayrılsın diye
        backgroundColor: s.textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: s.borderColor, space: 1),
      listTileTheme: ListTileThemeData(iconColor: s.primaryColor),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: s.primaryColor),
    );
  }
}
