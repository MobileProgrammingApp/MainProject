import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import eklendi
import 'core/app_scaffold.dart';
import 'core/app_theme.dart';
import 'navbars/login_screen.dart'; 

void main() async {
  // Flutter motorunu başlat (Async işlemler için gerekli)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hafızayı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final int? savedHouseId = prefs.getInt('saved_house_id');
  
  // Eğer savedHouseId varsa (null değilse), kullanıcı giriş yapmış demektir.
  // Bu durumda direkt AppScaffold (Ana Ekran) açılır.
  // Yoksa LoginScreen (Giriş Ekranı) açılır.
  Widget firstScreen = (savedHouseId != null) ? AppScaffold(houseId: savedHouseId) : const LoginScreen();

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