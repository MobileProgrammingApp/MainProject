import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_scaffold.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart'; 
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   print("🔥 Firebase initialized");

  // Hafızayı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final int? savedHouseId = prefs.getInt('saved_house_id');
  final int? savedMemberId = prefs.getInt('saved_member_id');
  
  // Eğer savedHouseId varsa (null değilse), kullanıcı giriş yapmış demektir.
  // Bu durumda direkt AppScaffold (Ana Ekran) açılır.
  // Yoksa LoginScreen (Giriş Ekranı) açılır.
  Widget firstScreen;

  if (savedHouseId == null) {
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