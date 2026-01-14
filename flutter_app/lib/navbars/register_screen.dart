import 'package:flutter/material.dart';
import 'api_service.dart'; 
import '../core/app_scaffold.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // EKLENDİ

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

      // ---------------------------------------------------------
      // 🛠️ DÜZELTME BURADA: HAFIZAYA KAYDETME İŞLEMİ EKLENDİ
      // ---------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();
      
      // API'den dönen 'user_id' (veya id) değerini alıp telefona kaydediyoruz.
      // NOT: PHP tarafında register.php dosyasının 'user_id' döndürdüğünden emin ol.
      // Eğer PHP id döndürmüyorsa, kayıt olduktan sonra otomatik login fonksiyonunu çağırmak gerekir.
      if (result['user_id'] != null) {
         await prefs.setInt('saved_house_id', int.parse(result['user_id'].toString()));
      }
      
      int newHouseId = int.parse(result['user_id'].toString());
      
      // Ev ismini de kaydedelim ki hemen görünsün
      await prefs.setString('saved_house_name', _houseNameController.text);
      // ---------------------------------------------------------
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AppScaffold(houseId: newHouseId)),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt Başarılı! Hoş geldiniz.")),
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
              _buildField("Şifre", _passwordController, isPassword: true),
              
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
  Widget _buildField(String hint, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller, 
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}