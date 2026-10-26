import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../core/notification_service.dart';
import '../../core/widgets/page_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool? _enabled; // null = hafızadan henüz okunmadı

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _enabled = prefs.getBool('notificationsEnabled') ?? true);
  }

  // Hafızaya kaydeder ve sunucudaki cihaz kaydını senkronize eder
  Future<void> _update(bool value) async {
    setState(() => _enabled = value);
    await NotificationService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(
        icon: Icons.notifications_rounded,
        title: "Bildirimler",
        subtitle: _enabled == null ? null : (_enabled! ? "Açık" : "Kapalı"),
      ),
      body: _enabled == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    value: _enabled!,
                    onChanged: _update,
                    title: const Text('Bu cihaza bildirim gönder', style: AppStyles.listTileTitle),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text("Sana görev atandığında, bir görev tamamlandığında, market listesine "
                          "ürün eklendiğinde ve yeni anket açıldığında haber verir."),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Bildirimler Ayarlar > \"Ben kimim?\" bölümünde seçili kişiye gelir.",
                    style: AppStyles.listTileSubtitle,
                  ),
                ),
              ],
            ),
    );
  }
}
