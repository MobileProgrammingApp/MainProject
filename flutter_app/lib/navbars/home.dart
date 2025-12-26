import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Örnek Anket Verisi (Normalde veritabanından gelir)
  String pollQuestion = "🍕 Bu akşam ne yiyelim?";
  Map<String, int> pollOptions = {
    "Pizza": 3,
    "Burger": 1,
    "Ev Yemeği": 2,
  };
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Modern Header
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            elevation: 0,
            backgroundColor: AppStyles.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Bizim Ev', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppStyles.primaryColor, Color(0xFF34495E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Özet Kartları
                  const Text('Hızlı Bakış', style: AppStyles.appBarTitle),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "İşler", "3 Bekliyor", Icons.task_alt, Colors.orange.shade100, 
                          () => widget.onTabChange(1)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSummaryCard(
                          "Market", "5 Ürün", Icons.shopping_bag_outlined, Colors.green.shade100, 
                          () => widget.onTabChange(2)
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 3. ANKET BÖLÜMÜ
                  _buildPollSection(),
                  
                  const SizedBox(height: 30),

                  // 4. Alt Menü Kısayolları
                  const Text('Diğer İşlemler', style: AppStyles.appBarTitle),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Özet Kart Widget'ı
  Widget _buildSummaryCard(String title, String count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppStyles.primaryColor, size: 30),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(count, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ANKET WIDGET'I
  Widget _buildPollSection() {
    int totalVotes = pollOptions.values.fold(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📊 Günün Anketi", style: TextStyle(fontWeight: FontWeight.bold, color: AppStyles.accentColor)),
              if (selectedOption != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(pollQuestion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...pollOptions.keys.map((option) {
            double percent = totalVotes == 0 ? 0 : pollOptions[option]! / totalVotes;
            bool isSelected = selectedOption == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (selectedOption == null) {
                      pollOptions[option] = pollOptions[option]! + 1;
                      selectedOption = option;
                    }
                  });
                },
                child: Stack(
                  children: [
                    // Arka Plan Progress Bar
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 45,
                      width: MediaQuery.of(context).size.width * percent * 0.75, // Oransal genişlik
                      decoration: BoxDecoration(
                        color: isSelected ? AppStyles.accentColor.withOpacity(0.3) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Metin Katmanı
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          Text("%${(percent * 100).toInt()}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionItem(Icons.people_alt_rounded, "Kişiler", () => widget.onTabChange(4)),
        _buildActionItem(Icons.info_rounded, "Ev Bilgi", () => widget.onTabChange(3)),
        _buildActionItem(Icons.notifications_active, "Duyuru", () {}),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppStyles.primaryColor),
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}