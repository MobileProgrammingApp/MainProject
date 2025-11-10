import 'package:flutter/material.dart';

// 1. Durumlu Widget Sınıfını Tanımlayın
class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

// 2. State Sınıfı
class _ChoresScreenState extends State<ChoresScreen> {
  // Görev verilerini bir Map<String, String> kullanarak isim ve atanan kişi olarak tutalım.
  // Bu, daha gerçekçi bir veri yapısı sağlar.
  final List<Map<String, String>> _pendingChores = [
    {'name': 'Çöpleri Çıkar', 'assigned': 'Ahmet'},
    {'name': 'Banyoyu Temizle', 'assigned': 'Ayşe'},
    {'name': 'Ortak Alanları Süpür', 'assigned': 'Herkes'},
  ];

  final List<Map<String, String>> _completedChores = [
    {'name': 'Bulaşıkları Yıka', 'assigned': 'Ben'},
    {'name': 'Faturayı Öde', 'assigned': 'Ahmet'},
  ];

  // YENİ GÖREV EKLEME MANTIĞI
  void _addNewChore(String name, String assignedUser) {
    setState(() {
      _pendingChores.add({'name': name, 'assigned': assignedUser});
    });
  }

  // GÖREVİ TAMAMLAMA MANTIĞI VE OTOMATİK SİLME
  void _completeChore(Map<String, String> chore) {
    setState(() {
      // 1. Bekleyenler listesinden çıkar
      _pendingChores.remove(chore);
      // 2. Tamamlananlar listesine ekle
      _completedChores.add(chore);
    });

    // Otomatik Silme Mantığı (5 saniye sonra)
    Future.delayed(const Duration(hours: 1), () {
      // Görev hala tamamlananlar listesindeyse sil
      if (_completedChores.contains(chore)) {
        setState(() {
          _completedChores.remove(chore);
        });
        print('Görev "${chore['name']}" otomatik olarak silindi.');
      }
    });
  }

  // MODALI GÖSTEREN FONKSİYON
  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // onAddChore callback'ini _addNewChore metodu ile bağladık.
          child: AddChoreForm(
            onAddChore: _addNewChore,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- A. AppBar Kodu (Başlık Çubuğu) ---
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

      // --- B. Floating Action Button Kodu ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskModal, // Modal açma fonksiyonuna bağlandı
        child: const Icon(Icons.add),
      ),

      // --- C. Body Kodu (Görev Listesi) ---
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Bekleyen Görevler Başlığı
          Text(
            'Şu Anda Bekleyen Görevler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),

          // Bekleyen Görev Kartları
          ..._pendingChores.map((chore) => _buildPendingChoreCard(chore, context)).toList(),

          const SizedBox(height: 30),

          // Tamamlanan Görevler Başlığı
          Text(
            'Bugün Tamamlananlar (1 saat sonra otomatik olarak silinir)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),

          // Tamamlanan Görev Kartları
          ..._completedChores.map((chore) => _buildCompletedChoreCard(chore)).toList(),
        ],
      ),
    );
  }

  // --- D. Yardımcı Widget Metotları ---
  // Tek bir bekleyen görev kartını oluşturan metot
  Widget _buildPendingChoreCard(Map<String, String> chore, BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          // Atanan kişinin baş harfi
          child: Text(chore['assigned']![0]),
        ),
        title: Text(
          chore['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Atanan: ${chore['assigned']}, Tekrar: Haftalık'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          onPressed: () {
            _completeChore(chore); // Görev tamamlama fonksiyonuna bağlandı
          },
        ),
      ),
    );
  }

  // Tek bir tamamlanmış görev kartını oluşturan metot
  Widget _buildCompletedChoreCard(Map<String, String> chore) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.grey),
      title: Text(
        chore['name']!,
        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
      ),
      subtitle: Text('Yapan: ${chore['assigned']} (Şimdi)', style: const TextStyle(color: Colors.grey)),
    );
  }
}

// Yeni görev ekleme form widget'ı
class AddChoreForm extends StatefulWidget {
  final Function(String name, String assignedUser) onAddChore;

  const AddChoreForm({
    super.key,
    required this.onAddChore,
  });

  @override
  State<AddChoreForm> createState() => _AddChoreFormState();
}

class _AddChoreFormState extends State<AddChoreForm> {
  String _choreName = '';
  String? _assignedUser;

  final List<String> _users = ['Ahmet', 'Ayşe', 'Ben', 'Herkes'];

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

          // 1. Görev Adı Girişi
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

          // 2. Atanacak Kişi Seçimi (Dropdown)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Kime Atansın?', // labelText kullanıldı
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            value: _assignedUser,
            items: _users.map((String user) {
              return DropdownMenuItem<String>(
                value: user,
                child: Text(user),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _assignedUser = newValue;
              });
            },
          ),
          const SizedBox(height: 30),

          // 3. Kaydet Butonu
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text(
              'Görevi Kaydet',
              style: TextStyle(fontSize: 16),
            ),
            onPressed: () {
              if (_choreName.isNotEmpty && _assignedUser != null) {
                widget.onAddChore(_choreName, _assignedUser!); // Veriyi üst widget'a yolla
                Navigator.pop(context); // Modalı kapat
              } else {
                // Kullanıcıya uyarı gösterilebilir (Snack bar vb.)
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