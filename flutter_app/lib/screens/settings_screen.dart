import 'package:flutter/material.dart';
import 'package:flutter_app/screens/notifications_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/manageHome_screen.dart';
import '../../core/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text('Ayarlar', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const SizedBox(height: 8),

          // 🔹 Profil 
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppStyles.primaryColor),
            title: const Text('Profil', style: AppStyles.listTileTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const Divider(),

          // 🔹 Ev Yönetim
          ListTile(
            leading: const Icon(Icons.home_work_outlined, color: AppStyles.primaryColor),
            title: const Text('Evi Yönet', style: AppStyles.listTileTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHomeScreen()));
            },
          ),
          const Divider(),

          // 🔹 Bildirim Ayarları
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppStyles.primaryColor),
            title: const Text('Bildirimler', style: AppStyles.listTileTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          const Divider(),

          // 🔹 Çıkış Yap
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Çıkış Yap',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                )),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Uygulamadan çıkmak istediğine emin misin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Evet'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // await AuthService().signOut();
                print("sign out yapildi");
              }
            },
          ),
        ],
      ),
    );
  }
}
