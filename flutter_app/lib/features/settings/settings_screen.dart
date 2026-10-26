import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../home/manage_home_screen.dart';
import '../../../core/api_service.dart';
import '../../../core/app_theme.dart';
import '../../../core/notification_service.dart';
import '../../../core/widgets/page_header.dart';

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
        final members = await ApiService.getFamilyMembers(houseId);
        if (mounted) {
          setState(() {
            houseMembers = members;

            // --- KİŞİ KONTROLÜ (Daha önce seçilen kişi silinmiş mi?) ---
            if (savedMemberId != null) {
              var exists = houseMembers.any(
                (m) => m['id'].toString() == savedMemberId.toString(),
              );

              if (exists) {
                selectedMemberId = savedMemberId.toString();
                _saveMemberName(prefs, selectedMemberId!);
              } else {
                selectedMemberId = null;
                prefs.remove('saved_member_id');
                prefs.remove('saved_member_name');
              }
            } else {
              if (selectedMemberId != null) {
                var exists = houseMembers.any(
                  (m) => m['id'].toString() == selectedMemberId,
                );
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
        debugPrint("Kişi çekme hatası: $e");
        setState(() => isLoading = false);
      }
    }
  }

  // Panelde "İyi günler, <ad>" yazabilmek için seçili üyenin adını sakla
  void _saveMemberName(SharedPreferences prefs, String memberId) {
    final member = houseMembers.firstWhere((m) => m['id'].toString() == memberId, orElse: () => null);
    if (member != null) prefs.setString('saved_member_name', member['name'].toString());
  }

  // 2. Kişi Seçilince Kaydet
  Future<void> _onMemberChanged(String? newId) async {
    if (newId == null) return;

    setState(() {
      selectedMemberId = newId;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_member_id', int.parse(newId));
    _saveMemberName(prefs, newId);

    // Bu cihazın bildirimleri artık seçilen üyeye gelsin (bildirimler açıksa)
    try {
      await NotificationService.syncToken();
    } catch (e) {
      debugPrint("Token gönderilirken hata oluştu: $e");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kişi seçimi ve bildirim ayarları kaydedildi"),
        ),
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
        icon: Icons.settings_rounded,
        title: "Ayarlar",
        subtitle: "Profil, ev üyeleri ve bildirimler",
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const SectionHeader(title: "Ben kimim?"),
          _buildMemberCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: "Hesap ve ev"),
          GroupedCard(
            dividerIndent: 72,
            children: [
              _menuTile(Icons.person_outline_rounded, "Profil", "Ev adı, e-posta ve şifre",
                  () => _open(const ProfileScreen())),
              _menuTile(Icons.people_alt_outlined, "Ev üyeleri", "Kişi ekle veya çıkar",
                  () => _open(const ManageHomeScreen()).then((_) => _loadSettings())),
              _menuTile(Icons.notifications_outlined, "Bildirimler", "Bildirimleri aç veya kapat",
                  () => _open(const NotificationSettingsScreen())),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
              leading: _badge(Icons.logout_rounded, AppStyles.deleteColor, const Color(0xFFFBE6E6)),
              title: const Text("Çıkış yap",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyles.deleteColor)),
              onTap: _confirmLogout,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _badge(IconData icon, Color color, Color soft) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      leading: _badge(icon, AppStyles.primaryColor, AppStyles.primarySoft),
      title: Text(title, style: AppStyles.listTileTitle),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppStyles.mutedTextColor),
      onTap: onTap,
    );
  }

  // "Ben kimim?": bu cihazın hangi üyeye ait olduğu (görev bildirimleri ve oylar için)
  Widget _buildMemberCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bu cihazı kim kullanıyor? Görev bildirimleri ve anket oyları bu kişiye göre işlenir.",
            style: AppStyles.listTileSubtitle,
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else if (houseMembers.isEmpty)
            OutlinedButton.icon(
              onPressed: () => _open(const ManageHomeScreen()).then((_) => _loadSettings()),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text("Önce eve bir kişi ekle"),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: houseMembers.map<Widget>((member) {
                final id = member['id'].toString();
                return ChoiceChip(
                  avatar: selectedMemberId == id ? null : const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text(member['name'].toString()),
                  selected: selectedMemberId == id,
                  onSelected: (_) => _onMemberChanged(id),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Bu cihazda oturumu kapatmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppStyles.deleteColor),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Bildirimleri kapat, sunucudaki oturumu kapat, yerel verileri sil
    await ApiService.logout();
    if (!mounted) return;

    // Geçmişi silerek giriş ekranına git (geri tuşuyla uygulamaya dönülemez)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
