import 'package:flutter/material.dart';


class ManageHomeScreen extends StatelessWidget {
  final userRole = "owner"; // or member
  const ManageHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ev Yönetimi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Evdeki Kişiler:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Örnek kullanıcı listesi
          for (var person in ['Ahmet', 'Ayşe', 'Mehmet'])
            ListTile(
              title: Text(person),
              trailing: userRole == "owner"
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        // buraya kişiyi silme işlemi eklenebilir
                        print('$person çıkarıldı');
                      },
                    )
                  : null, // normal kullanıcı sadece görür
            ),

          const SizedBox(height: 20),

          if (userRole == "owner")
            ElevatedButton.icon(
              onPressed: () {
                // kişileri ekleme ekranı aç
                print('Yeni kişi ekleme');
              },
              icon: const Icon(Icons.add),
              label: const Text('Kişi Ekle'),
            ),
        ],
      ),
    );
  }
}
