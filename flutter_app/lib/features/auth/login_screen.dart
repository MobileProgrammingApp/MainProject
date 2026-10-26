import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/homepal_mark.dart';
import '../../core/app_scaffold.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen alanları doldurun")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        'saved_house_id',
        int.parse(result['user_id'].toString()),
      );
      await prefs.setString('saved_house_name', result['house_name']);
      // Oturum token'ı ApiService.login içinde şifreli depolamaya kaydedildi

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AppScaffold(houseId: int.parse(result['user_id'].toString())),
        ),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Giriş başarısız")),
      );
    }
  }

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
              // Açılış animasyonunun bittiği kompozisyonla aynı amblem ve yazı
              const BrandHero(tag: BrandHero.mark, child: HomePalMark(size: kBrandMarkSize)),
              const BrandHero(tag: BrandHero.wordmark, child: HomePalWordmark()),
              const SizedBox(height: 6),
              const BrandHero(
                tag: BrandHero.tagline,
                child: Text("Evin ortak asistanı", style: AppStyles.listTileSubtitle),
              ),
              const SizedBox(height: 36),

              // E-Posta Kutusu
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ev ortak e-postası',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Şifre Kutusu
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text("Şifremi unuttum"),
                ),
              ),
              const SizedBox(height: 10),

              // Giriş Butonu
              FilledButton(
                onPressed: _isLoading ? null : _login,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text("Giriş yap", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),

              // Kayıt Ol Linki
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                ),
                child: const Text.rich(
                  TextSpan(
                    text: "Henüz bir ev hesabın yok mu? ",
                    style: TextStyle(color: AppStyles.mutedTextColor),
                    children: [
                      TextSpan(text: "Yeni ev oluştur", style: TextStyle(color: AppStyles.primaryColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
