import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/session.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yayın sürümünde log basılmasın (sunucu cevapları, hata detayları vb.
  // logcat üzerinden okunabiliyordu). Loglar için print değil debugPrint kullanın.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Seçilen tema ilk kareden önce okunur, yoksa açılış bir an yanlış temayla
  // çizilir. Firebase, bildirimler ve oturum hazırlığı SplashScreen'de,
  // açılış animasyonu oynarken yapılır.
  await AppTheme.loadMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ayarlar'da tema değişince uygulama yeniden kurulmadan yeni temaya geçer
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'HomePal',
        debugShowCheckedModeBanner: false,
        // Oturum düşünce (HTTP 401) her yerden giriş ekranına dönebilmek için
        navigatorKey: Session.navigatorKey,
        scaffoldMessengerKey: Session.messengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        // Varsayılan: açık temada koyu, koyu temada açık durum çubuğu ikonları.
        // Mavi başlık bandı (PageHeader) kendi bölgesinde bunu beyaza çevirir.
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: (Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
