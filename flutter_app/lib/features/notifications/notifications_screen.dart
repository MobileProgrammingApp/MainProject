import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  
  // ==========================================
  // 🛑 BACKEND (DOKUNMA)
  // Bu kısım ayarları telefonun hafızasına kaydeder.
  // ==========================================
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  // Hafızadan ayarı oku
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // Hafızaya yeni ayarı kaydet
  Future<void> _updateNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Ekranın görüntüsü buradadır.
  // Yazıları, switch rengini vb. değiştirebilirsin.
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Bildirimleri Aç/Kapat'),
            // Sağ taraftaki açma kapama anahtarı
            trailing: Switch(
              value: _notificationsEnabled,
              // Anahtara basınca Backend fonksiyonu çalışır:
              onChanged: (value) => _updateNotificationPreference(value),
              activeColor: Colors.green, // Açıkken renk (İsteğe bağlı)
            ),
          ),
        ],
      ),
    );
  }
}