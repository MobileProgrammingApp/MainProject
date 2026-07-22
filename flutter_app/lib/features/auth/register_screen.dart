import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ (DOKUNMA)
  // Bu değişkenler metin kutularına girilen yazıları tutar.
  // ==========================================
  final TextEditingController _houseNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ==========================================
  // 🛑 BACKEND FONKSİYONU (DOKUNMA)
  // Bu fonksiyon "Kaydı Tamamla" butonuna basılınca çalışır.
  // Sunucuya verileri gönderir ve sonucu kontrol eder.
  // ==========================================
  void _register() async {
    // Alanlar boş mu kontrol et
    if (_houseNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir e-posta adresi girin")),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalı")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- API İSTEĞİ BURADA YAPILIYOR ---
    final result = await ApiService.register(
      _houseNameController.text,
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false); 

    // --- SONUÇ KONTROLÜ ---
    if (result['status'] == 'success') {
      if (!mounted) return;

      // Kayıt sadece hesabı oluşturur; e-posta doğrulanana kadar giriş
      // engellendiği için burada otomatik giriş yapmıyoruz.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Kayıt başarılı! Lütfen e-postanızı doğrulayın.")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Bir hata oluştu")),
      );
    }
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Kayıt ekranının görüntüsü buradadır.
  // Renkleri, yazı tiplerini ve boşlukları buradan değiştirebilirsin.
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ev Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView( 
          child: Column(
            children: [
              const Text(
                "Tüm aile üyeleri bu e-posta ve şifre ile giriş yapacak.", 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 30),
              
              // Ev Adı Kutusu
              _buildField("Ev Adı (Örn: Bizim Yuva)", _houseNameController),
              const SizedBox(height: 15),
              
              // E-Posta Kutusu
              _buildField("Ortak E-posta", _emailController),
              const SizedBox(height: 15),
              
              // Şifre Kutusu
              _buildField(
                "Şifre",
                _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              
              const SizedBox(height: 30),
              
              // Kayıt Butonu (Logic burada bağlanıyor)
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register, // Butona basılınca Backend fonksiyonu çalışır
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50), // Buton rengi
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Kaydı Tamamla", style: TextStyle(color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Yardımcı Tasarım Parçası (Kutucukların şekli burada belirlenir)
  Widget _buildField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}