import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../navbars/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/manageHome_screen.dart';
import '../../core/app_theme.dart';

final String baseUrl = "https://swordarchitecture.com/api"; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ (DOKUNMA)
  // Bu değişkenler sunucudan gelen kişi listesini tutar.
  // ==========================================
  List<dynamic> houseMembers = [];
  String? selectedMemberId; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI (DOKUNMA)
  // Burası ayarları yükler, kişileri çeker ve kaydeder.
  // ==========================================

  // 1. Ayarları ve Kişileri Yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int? houseId = prefs.getInt('saved_house_id');
    int? savedMemberId = prefs.getInt('saved_member_id'); 

    if (houseId != null) {
      try {
        final response = await http.get(Uri.parse("$baseUrl/get_members.php?house_id=$houseId"));
        if (response.statusCode == 200) {
          setState(() {
            houseMembers = json.decode(response.body);
            
            // --- KİŞİ KONTROLÜ (Daha önce seçilen kişi silinmiş mi?) ---
            if (savedMemberId != null) {
              var exists = houseMembers.any((m) => m['id'].toString() == savedMemberId.toString());
              
              if (exists) {
                selectedMemberId = savedMemberId.toString();
              } else {
                selectedMemberId = null; 
                prefs.remove('saved_member_id'); 
              }
            } else {
               if (selectedMemberId != null) {
                  var exists = houseMembers.any((m) => m['id'].toString() == selectedMemberId);
                  if (!exists) {
                    selectedMemberId = null;
                  }
               }
            }
            // ---------------------------------------------------------
            
            isLoading = false;
          });
        }
      } catch (e) {
        print("Kişi çekme hatası: $e");
        setState(() => isLoading = false);
      }
    }
  }

  // 2. Kişi Seçilince Kaydet
  Future<void> _onMemberChanged(String? newId) async {
    if (newId == null) return;

    setState(() {
      selectedMemberId = newId;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_member_id', int.parse(newId));
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kişi seçimi kaydedildi")));
    }
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Ayarlar menüsünün görüntüsü buradadır.
  // İkonları, yazıları ve sıralamayı değiştirebilirsin.
  // ==========================================
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

          // --- "BEN KİMİM?" KUTUSU ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("👤 Ben Kimim?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text("Uygulamayı hangi kişi olarak kullanıyorsunuz?", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                
                isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedMemberId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text("Lütfen kendinizi seçin"),
                      items: houseMembers.map<DropdownMenuItem<String>>((dynamic member) {
                        return DropdownMenuItem<String>(
                          value: member['id'].toString(),
                          child: Text(member['name']),
                        );
                      }).toList(),
                      onChanged: _onMemberChanged, // Backend fonksiyonunu tetikler
                    ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(),

          // 🔹 Profil Menüsü
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppStyles.primaryColor),
            title: const Text('Profil', style: AppStyles.listTileTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const Divider(),

          // 🔹 Ev Yönetim Menüsü
          ListTile(
            leading: const Icon(Icons.home_work_outlined, color: AppStyles.primaryColor),
            title: const Text('Evi Yönet (Kişi Ekle/Sil)', style: AppStyles.listTileTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const ManageHomeScreen())
              ).then((value) {
                // Geri dönünce listeyi yenile (Backend işlemi)
                _loadSettings(); 
              });
            },
          ),

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

          // 🔹 Çıkış Yap Butonu
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Çıkış Yap',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                )),
            onTap: () async {
              // Çıkış onayı penceresi
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Tüm verileri sil

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, 
                );
              }
            },
          ),
        ],
      ),
    );
  }
}