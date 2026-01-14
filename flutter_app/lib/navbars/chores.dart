import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = "https://swordarchitecture.com/api";

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ
  // ==========================================
  List<Map<String, String>> _pendingChores = [];
  List<Map<String, String>> _completedChores = [];
  
  int? currentUserId;
  List<dynamic> _houseMembers = []; 
  bool _isLoading = true; // Yükleniyor durumu eklendi

  @override
  void initState() {
    super.initState();
    // didChangeDependencies içinde çağrılacak
  }

  // Sayfa her ekrana geldiğinde verileri yenile
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserAndData(); 
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI
  // ==========================================
  
  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. DÜZELTME: Hafızayı tazele
    await prefs.reload();

    // 2. DÜZELTME: Eski verileri temizle ve yükleniyor moduna geç
    if (mounted) {
      setState(() {
        _pendingChores.clear();
        _completedChores.clear();
        _houseMembers.clear();
        _isLoading = true; // Yükleniyor...
        currentUserId = prefs.getInt('saved_house_id');
      });
    }

    if (currentUserId != null) {
      // Sırasıyla verileri çek
      await _fetchHouseMembers(); 
      await _fetchChores();
    } else {
      // ID yoksa yüklemeyi bitir
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchHouseMembers() async {
    if (currentUserId == null) return;
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_members.php?house_id=$currentUserId"));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _houseMembers = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      print("Üye çekme hatası: $e");
    }
  }

  Future<void> _fetchChores() async {
    if (currentUserId == null) return;

    // ApiService.getChores fonksiyonuna ID göndermeliyiz (Backend düzeltmesiyle uyumlu olması için)
    // Eğer ApiService'deki getChores parametre almıyorsa, orayı da güncellemen gerekebilir.
    // Şimdilik varsayılan haliyle bırakıyorum ama ID filtresi önemli.
    List data = await ApiService.getChores(currentUserId!); 
    
    if (mounted) {
      setState(() {
        _pendingChores = data
            .where((c) {
              var val = c['is_done'];
              return val == 0 || val == "0" || val == false || val == "false" || val == null;
            })
            .map((c) => {
                  'id': c['id'].toString(),
                  'name': c['task_name'].toString(),
                  'assigned': c['assigned_to_id'].toString(),
                })
            .toList();

        _completedChores = data
            .where((c) {
               var val = c['is_done'];
               return val == 1 || val == "1" || val == true || val == "true";
            })
            .map((c) => {
                  'id': c['id'].toString(),
                  'name': c['task_name'].toString(),
                  'assigned': c['assigned_to_id'].toString(),
                })
            .toList();
        
        _isLoading = false; // Yükleme bitti
      });
    }
  }

  Future<void> _addNewChore(String name, String assignedUserId) async {
    if (currentUserId == null) return;
    int assignId = int.parse(assignedUserId);
    bool success = await ApiService.addChore(currentUserId!, assignId, name);

    if (success) {
      await _fetchChores(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Görev eklendi")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hata oluştu")),
        );
      }
    }
  }

  Future<void> _completeChore(Map<String, String> chore) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_chore.php"),
        body: {"id": chore['id']},
      );
      if (response.statusCode == 200) {
        _fetchChores();
      }
    } catch (e) {
      print("Güncelleme hatası: $e");
    }
  }

  Future<void> _deleteChore(String choreId) async {
    bool success = await ApiService.deleteChore(int.parse(choreId));
    if (success) {
      _fetchChores();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Görev silindi")));
      }
    }
  }

  // ==========================================
  // 🎨 TASARIM ALANI
  // ==========================================

  void _showAddTaskModal() async {
    await _fetchHouseMembers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddChoreForm(
            onAddChore: _addNewChore,
            members: _houseMembers, 
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏡 Ev İşleri Panosu'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                label: Text('${_completedChores.length}/${_pendingChores.length + _completedChores.length} Görev', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.amber.shade50,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_chore", 
        onPressed: _showAddTaskModal, 
        child: const Icon(Icons.add),
      ),
      // Yükleniyor kontrolü eklendi
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserAndData, // Aşağı çekince yenile
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  Text(
                    'Şu Anda Bekleyen Görevler',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  if (_pendingChores.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Bekleyen görev yok!", style: TextStyle(color: Colors.grey)),
                    ),
                  ..._pendingChores.map((chore) => _buildPendingChoreCard(chore, context)),

                  const SizedBox(height: 30),

                  Text(
                    'Bugün Tamamlananlar',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  if (_completedChores.isEmpty && _pendingChores.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Henüz bir görev tamamlanmadı.", style: TextStyle(color: Colors.grey)),
                    ),
                  ..._completedChores.map((chore) => _buildCompletedChoreCard(chore)),
                ],
              ),
            ),
    );
  }

  // --- KART TASARIMLARI (AYNI KALDI) ---
  Widget _buildPendingChoreCard(Map<String, String> chore, BuildContext context) {
    String assignedName = chore['assigned']!; 
    
    var member = _houseMembers.firstWhere(
      (m) => m['id'].toString() == chore['assigned'], 
      orElse: () => null 
    );

    if (member != null) {
      assignedName = member['name'];
    } else {
      assignedName = "Silinmiş Kişi"; 
    }

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          child: Text(assignedName.isNotEmpty ? assignedName[0].toUpperCase() : "?"),
        ),
        title: Text(
          chore['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Atanan: $assignedName'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          onPressed: () {
            _completeChore(chore); 
          },
        ),
      ),
    );
  }

  Widget _buildCompletedChoreCard(Map<String, String> chore) {
    String assignedName = chore['assigned']!;
    
    var member = _houseMembers.firstWhere(
      (m) => m['id'].toString() == chore['assigned'], 
      orElse: () => null
    );

    if (member != null) {
      assignedName = member['name'];
    } else {
      assignedName = "Silinmiş Kişi";
    }

    return Card(
      color: Colors.grey.shade100,
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.grey),
        title: Text(
          chore['name']!,
          style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
        ),
        subtitle: Text('Yapan: $assignedName', style: const TextStyle(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            _deleteChore(chore['id']!); 
          },
        ),
      ),
    );
  }
}

// --- FORM WIDGET (AYNI KALDI) ---
class AddChoreForm extends StatefulWidget {
  final Function(String name, String assignedUserId) onAddChore;
  final List<dynamic> members; 

  const AddChoreForm({
    super.key,
    required this.onAddChore,
    required this.members,
  });

  @override
  State<AddChoreForm> createState() => _AddChoreFormState();
}

class _AddChoreFormState extends State<AddChoreForm> {
  String _choreName = '';
  String? _assignedUserId; 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '➕ Yeni Ev İşi Ekle',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ev İşinin Adı (Örn: Çöpleri Çıkar)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cleaning_services),
            ),
            onChanged: (value) {
              _choreName = value;
            },
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Kime Atansın?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            value: _assignedUserId,
            items: widget.members.map<DropdownMenuItem<String>>((dynamic member) {
              return DropdownMenuItem<String>(
                value: member['id'].toString(), 
                child: Text(member['name']),    
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _assignedUserId = newValue;
              });
            },
            hint: widget.members.isEmpty 
              ? const Text("Kişi bulunamadı") 
              : const Text("Kişi Seçiniz"),
          ),
          const SizedBox(height: 30),

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Görevi Kaydet', style: TextStyle(fontSize: 16)),
            onPressed: () {
              if (_choreName.isNotEmpty && _assignedUserId != null) {
                widget.onAddChore(_choreName, _assignedUserId!); 
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}