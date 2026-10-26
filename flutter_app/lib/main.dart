import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/session.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Yayın sürümünde log basılmasın (sunucu cevapları, hata detayları vb.
  // logcat üzerinden okunabiliyordu). Loglar için print değil debugPrint kullanın.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Firebase, bildirimler ve oturum hazırlığı SplashScreen'de, açılış
  // animasyonu oynarken yapılır; ilk kare beklemeden çizilir.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomePal',
      debugShowCheckedModeBanner: false,
      // Oturum düşünce (HTTP 401) her yerden giriş ekranına dönebilmek için
      navigatorKey: Session.navigatorKey,
      scaffoldMessengerKey: Session.messengerKey,
      theme: AppTheme.light,
      // Varsayılan: açık zemin üzerinde koyu durum çubuğu ikonları.
      // Mavi başlık bandı (PageHeader) kendi bölgesinde bunu beyaza çevirir.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
