import 'package:flutter/material.dart';
import '../core/api_service.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class ManageHomeScreen extends StatefulWidget {
  const ManageHomeScreen({super.key});

  @override
  State<ManageHomeScreen> createState() => _ManageHomeScreenState();
}

class _ManageHomeScreenState extends State<ManageHomeScreen> {
  
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ (DOKUNMA)
  // Bu değişkenler kişi listesini ve ev ID'sini tutar.
  // ==========================================
  int? currentHouseId;
  List<dynamic> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouseId();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI (DOKUNMA)
  // Sunucuyla konuşan, kişi ekleyen/silen kodlar.
  // Buradaki kodları değiştirirsen ekleme/silme bozulur.
  // ==========================================

  // 1. Ev ID'sini Hafızadan Oku
  Future<void> _loadHouseId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentHouseId = prefs.getInt('saved_house_id');
    });

    if (currentHouseId != null) {
      _fetchMembers();
    }
  }

  // 2. Üyeleri Listele
  void _fetchMembers() async {
    if (currentHouseId == null) return; 

    setState(() => isLoading = true);
    final data = await ApiService.getFamilyMembers(currentHouseId!); 
    setState(() {
      members = data;
      isLoading = false;
    });
  }

  // 3. Yeni Üye Ekleme İşlemi (API)
  Future<void> _apiAddMember(String name) async {
    if (currentHouseId == null) return;

    bool success = await ApiService.addFamilyMember(
      currentHouseId!, 
      name
    );
    
    if (success) {
      _fetchMembers(); // Listeyi yenile
      if (mounted) {
        Navigator.pop(context); // Pencereyi kapat
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kişi eklendi")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
      }
    }
  }

  // 4. Silme İşlemi (API)
  Future<void> _apiDeleteMember(int memberId) async {
    bool success = await ApiService.deleteFamilyMember(memberId);
    
    if (success) {
      _fetchMembers(); // Listeyi yenile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kişi silindi")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silme başarısız oldu")));
      }
    }
  }
  // ==========================================
  // 🏁 BACKEND BİTİŞ
  // ==========================================


  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Buradan aşağısı ekran görüntüsüyle ilgilidir.
  // Renkleri, kartları ve ikonları değiştirebilirsin.
  // ==========================================

  // --- EKLEME PENCERESİ TASARIMI ---
  void _showAddMemberDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Kişi Ekle"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Kişi Adı (Örn: Ayşe)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _apiAddMember(nameController.text); // Backend çağrısı
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  // --- SİLME ONAY PENCERESİ TASARIMI ---
  void _showDeleteConfirmDialog(String name, int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: Text("$name kişisini silmek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      _apiDeleteMember(id); // Backend çağrısı
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ev Sakinleri")),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_member", 
        onPressed: _showAddMemberDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Text("Henüz kimse eklenmemiş."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            member['name'][0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Ev Sakini"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            // Silme butonuna basınca onay penceresi açılır
                            _showDeleteConfirmDialog(member['name'], int.parse(member['id'].toString()));
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}