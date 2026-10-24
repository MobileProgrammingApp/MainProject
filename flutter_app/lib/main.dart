import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_service.dart';
import 'core/app_scaffold.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/session.dart';
import 'features/auth/login_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yayın sürümünde log basılmasın (sunucu cevapları, hata detayları vb.
  // logcat üzerinden okunabiliyordu). Loglar için print değil debugPrint kullanın.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("🔥 Firebase initialized");

  await NotificationService.initialize();

  // Eski sürümden kalan ortak token'ı bu cihaza özel bir token'la değiştir
  // (eski sürümden gelen token bu sırada şifreli depoya da taşınır).
  // Sunucu oturumu reddederse veriler temizlenir; o yüzden hafıza bundan sonra okunuyor.
  await ApiService.renewSharedToken();

  // Hafızayı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final int? savedHouseId = prefs.getInt('saved_house_id');
  final int? savedMemberId = prefs.getInt('saved_member_id');
  final String? token = await Session.getToken();

  // Eğer savedHouseId ve oturum token'ı varsa kullanıcı giriş yapmış demektir.
  // Bu durumda direkt AppScaffold (Ana Ekran) açılır.
  // Yoksa LoginScreen (Giriş Ekranı) açılır.
  Widget firstScreen;

  if (savedHouseId == null || token == null) {
    firstScreen = const LoginScreen();
  } else if (savedMemberId == null) {
    // 2. Durum: Giriş yapılmış ama "Ben Kimim" seçilmemiş -> Üye seçme ekranına git
    // Not: Buraya kendi üye seçme sayfanızın adını yazın
    // firstScreen = MemberSelectionScreen(houseId: savedHouseId); 
    firstScreen = const LoginScreen(); // Şimdilik güvenli liman
  } else {
    // 3. Durum: Her iki bilgi de var -> Direkt ana sayfaya git
    firstScreen = AppScaffold(houseId: savedHouseId);
  }

  runApp(MyApp(startScreen: firstScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  
  // startScreen parametresini alıyoruz
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evim Uygulaması',
      debugShowCheckedModeBanner: false,
      // Oturum düşünce (HTTP 401) her yerden giriş ekranına dönebilmek için
      navigatorKey: Session.navigatorKey,
      scaffoldMessengerKey: Session.messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppStyles.primaryColor,
        scaffoldBackgroundColor: AppStyles.backgroundColor,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: startScreen, // Başlangıç ekranı burada belirleniyor
    );
  }
}