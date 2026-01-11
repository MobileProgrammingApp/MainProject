import 'package:flutter/material.dart';
import 'core/app_scaffold.dart';
import 'core/app_theme.dart';
import 'navbars/login_screen.dart'; // Bu importu eklediğinden emin ol

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      // DÜZELTME BURADA: Uygulama artık LoginScreen ile başlıyor
      home: const LoginScreen(), 
    );
  }
}