import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';
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

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 8 karakter olmalı")),
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
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(
        icon: Icons.add_home_rounded,
        title: "Yeni ev oluştur",
        subtitle: "Tüm ev halkı bu hesapla giriş yapar",
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.styles.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: context.styles.primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Evin ortak e-postası ve şifresiyle tüm aile üyeleri giriş yapar; herkes uygulamada kendi adını seçer.",
                    style: TextStyle(color: context.styles.textColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _houseNameController,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: "Ev adı (örn: Bizim Yuva)",
              prefixIcon: Icon(Icons.home_outlined),
              counterText: "",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: "Ortak e-posta", prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            decoration: InputDecoration(
              hintText: "Şifre (en az 8 karakter)",
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isLoading ? null : _register,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text("Kaydı tamamla", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
