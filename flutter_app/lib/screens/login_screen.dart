import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_scaffold.dart';
import 'register_screen.dart';
import '../core/api_service.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; 

  // ==========================================
  // 🛑 BACKEND FONKSİYONU (DOKUNMA)
  // Bu fonksiyon "Giriş Yap" butonuna basılınca çalışır.
  // API'ye istek atar, cevabı alır ve telefonu hafızasına kaydeder.
  // ==========================================
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen alanları doldurun")));
      return;
    }

    setState(() => _isLoading = true);

    // --- API İSTEĞİ BURADA YAPILIYOR ---
    final result = await ApiService.login(
      _emailController.text, 
      _passwordController.text
    );

    setState(() => _isLoading = false);

    if (result['status'] == 'success') {      
      // --- BAŞARILI İSE HAFIZAYA KAYDETME ---
      final prefs = await SharedPreferences.getInstance();
      
      // result['user_id'] veritabanından gelen ID'dir.
      // Bunu telefona kaydediyoruz ki uygulama açılınca hatırlasın.
      await prefs.setInt('saved_house_id', int.parse(result['user_id'].toString()));
      await prefs.setString('saved_house_name', result['house_name']); 

      String? token = await FirebaseMessaging.instance.getToken();


      if (!mounted) return;
      // Ana sayfaya yönlendir
        Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AppScaffold(houseId: int.parse(result['user_id'].toString()))),
        (route) => false, // Geçmişteki tüm rotaları iptal et
        );
      } else {
      // --- HATA VARSA UYARI GÖSTER ---
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Giriş başarısız")),
      );
    }
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Giriş ekranının görüntüsü buradadır.
  // Logoyu, kutucukları ve renkleri buradan değiştirebilirsin.
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work_rounded, size: 80, color: AppStyles.primaryColor),
              const SizedBox(height: 20),
              const Text("Ev Asistanı", style: AppStyles.appBarTitle),
              const SizedBox(height: 40),
              
              // E-Posta Kutusu
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Ev Ortak Maili',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              // Şifre Kutusu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),

              // Giriş Butonu
              _isLoading 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: _login, // Butona basılınca Backend fonksiyonu çalışır
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
              
              // Kayıt Ol Linki
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: const Text("Henüz bir ev hesabınız yok mu? Kaydol", style: TextStyle(color: AppStyles.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}