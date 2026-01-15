import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/api_service.dart';
import 'home_info_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==========================================
  // 🛑 BACKEND DEĞİŞKENLERİ (DOKUNMA)
  // Buradaki değişkenler sunucudan gelen verileri tutar.
  // ==========================================
  String houseName = "Yükleniyor...";
  int pendingChoresCount = 0;
  int pendingShoppingCount = 0;
  bool isLoading = true;
  Timer? _timer;
  int? currentUserId;
  int? currentMemberId;
  int? currentHouseId; 

  // Anket Verileri
  String pollQuestion = "";
  List<dynamic> pollOptions = [];
  bool hasActivePoll = false;
  bool hasVoted = false; 
  int? activePollId;
  int? votedOptionId; 

  @override
  void initState() {
    super.initState();
    _loadHomeData(); 
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 🛑 BACKEND FONKSİYONLARI (DOKUNMA)
  // Veri çekme, oy verme ve zamanlayıcı işlemleri.
  // ==========================================

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadHomeData(isSilent: true);
    });
  }

  Future<void> _loadHomeData({bool isSilent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    int? houseId = prefs.getInt('saved_house_id');
    int? memberId = prefs.getInt('saved_member_id');
    
    if (houseId != null) {
      currentHouseId = houseId;
      currentMemberId = memberId;

      // 🛠️ DÜZELTME: Yükleme başladığı an eski veriyi temizle
      if (!isSilent) {
        setState(() {
          isLoading = true;
          houseName = "Yükleniyor..."; // Eski isim yerine bunu yaz
          pendingChoresCount = 0;      // Sayıları sıfırla
          pendingShoppingCount = 0;
        });
      }
      final stats = await ApiService.getHomeStats(houseId);
      final pollData = await ApiService.getActivePoll(houseId, memberId ?? 0);

      if (mounted) {
        setState(() {
          if (stats.isNotEmpty && stats['status'] == 'success') {
            houseName = stats['house_name'];
            pendingChoresCount = int.parse(stats['pending_chores'].toString());
            pendingShoppingCount = int.parse(stats['pending_items'].toString());
          }

          if (pollData.isNotEmpty && pollData['status'] == 'success') {
            hasActivePoll = true;
            activePollId = int.parse(pollData['poll_id'].toString());
            pollQuestion = pollData['question'];
            pollOptions = pollData['options'];
            hasVoted = pollData['has_voted'] == true;
            votedOptionId = pollData['voted_option_id'] != null ? int.parse(pollData['voted_option_id'].toString()) : null;
          } else {
            hasActivePoll = false;
          }
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVote(int optionId) async {
    if (currentMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Oy vermek için lütfen Ayarlar'dan kim olduğunuzu seçin."),
          backgroundColor: Colors.red,
        )
      );
      widget.onTabChange(4); 
      return;
    }

    if (hasVoted) return;

    bool success = await ApiService.votePoll(activePollId!, optionId, currentHouseId!, currentMemberId!);
    
    if (success) {
      await _loadHomeData(isSilent: true);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oyunuz kaydedildi!")));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
    }
  }
  // ==========================================
  // 🏁 BACKEND FONKSİYONLARI BİTİŞ
  // ==========================================


  // ==========================================
  // ⚠️ KARIŞIK ALAN (ANKET OLUŞTURMA PENCERESİ)
  // Burası tasarım kodudur AMA "Oluştur" butonunun içi Backend'dir.
  // ==========================================
  void _showCreatePollDialog() {
    final TextEditingController questionCtrl = TextEditingController();
    final List<TextEditingController> optionCtrls = [
      TextEditingController(),
      TextEditingController()
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Yeni Anket Oluştur"), // Tasarım
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(labelText: "Soru (Örn: Ne yiyelim?)"),
                  ),
                  const SizedBox(height: 15),
                  const Text("Seçenekler:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(optionCtrls.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: optionCtrls[index],
                        decoration: InputDecoration(
                          labelText: "${index + 1}. Seçenek",
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setStateDialog(() {
                        optionCtrls.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Seçenek Ekle"),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
              
              // --- 🛑 BURASI BACKEND İŞLEMİDİR ---
              ElevatedButton(
                onPressed: () async {
                  int? targetId = currentHouseId ?? currentUserId; 
                  if (targetId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Oturum bilgisi yüklenemedi. Lütfen sayfayı yenileyin."))
                    );
                    return; 
                  }
                  String q = questionCtrl.text.trim();
                  List<String> opts = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                  if (q.isNotEmpty && opts.length >= 2) {
                    Navigator.pop(ctx);
                    bool success = await ApiService.createPoll(targetId, q, opts); // API Çağrısı
                    
                    if (success) {
                      _loadHomeData(); 
                      if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anket oluşturuldu!")));
                      }
                    } else {
                      if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anket oluşturulurken hata oluştu.")));
                      }
                    }
                  } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Soru ve en az 2 seçenek girin")));
                  }
                },
                child: const Text("Oluştur"),
              )
              // --- 🏁 BACKEND İŞLEMİ BİTİŞ ---
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 🎨 TASARIM ALANI (FRONTEND)
  // Burası ana ekranın görüntüsüdür. Renkleri, kartları,
  // yazıları buradan değiştirebilirsin.
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async { await _loadHomeData(isSilent: false); },
        color: AppStyles.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Üstteki Renkli Alan (App Bar)
            SliverAppBar(
              expandedHeight: 150.0,
              pinned: true,
              elevation: 0,
              backgroundColor: AppStyles.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  isLoading ? '...' : houseName, // Ev ismi burada yazar
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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

            // Sayfanın İçeriği
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hızlı Bakış', style: AppStyles.appBarTitle),
                    const SizedBox(height: 15),
                    
                    // İşler ve Market Kartları
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard("İşler", "$pendingChoresCount Bekliyor", Icons.task_alt, Colors.orange.shade100, () => widget.onTabChange(1)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSummaryCard("Market", "$pendingShoppingCount Ürün", Icons.shopping_bag_outlined, Colors.green.shade100, () => widget.onTabChange(2)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- ANKET BÖLÜMÜ (Tasarım kodları aşağıdadır) ---
                    _buildPollSection(),
                    
                    const SizedBox(height: 30),

                    const Text('Diğer İşlemler', style: AppStyles.appBarTitle),
                    const SizedBox(height: 12),
                    
                    // Alt Kısımdaki Butonlar
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET TASARIM METOTLARI ---

  Widget _buildPollSection() {
    // 1. Aktif Anket Yoksa -> OLUŞTUR BUTONU TASARIMI
    if (!hasActivePoll) {
       return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
        ),
        child: Column(
          children: [
            const Text("Şu an aktif bir anket yok.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showCreatePollDialog, 
              icon: const Icon(Icons.add_chart), 
              label: const Text("Anket Oluştur"),
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.accentColor, foregroundColor: Colors.white),
            )
          ],
        ),
       );
    }

    // 2. Aktif Anket Varsa -> OYLAMA EKRANI TASARIMI
    int totalVotes = 0;
    for (var opt in pollOptions) {
      totalVotes += int.parse(opt['vote_count'].toString());
    }

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
              if (hasVoted) const Chip(label: Text("Oy Verildi", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green, padding: EdgeInsets.all(0),),
            ],
          ),
          const SizedBox(height: 10),
          Text(pollQuestion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          ...pollOptions.map((option) {
            int voteCount = int.parse(option['vote_count'].toString());
            int optionId = int.parse(option['id'].toString());
            
            // ⚠️ MATEMATİKSEL HESAP (Yüzde hesaplama)
            double percent = totalVotes == 0 ? 0 : voteCount / totalVotes;
            
            bool isMyChoice = votedOptionId == optionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: hasVoted ? null : () => _handleVote(optionId), 
                child: Stack(
                  children: [
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Animasyonlu Yüzde Çubuğu
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 45,
                      width: MediaQuery.of(context).size.width * percent * 0.75,
                      decoration: BoxDecoration(
                        color: isMyChoice 
                            ? AppStyles.accentColor.withOpacity(0.6) 
                            : (hasVoted ? Colors.grey.shade400 : AppStyles.accentColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option['option_text'], style: TextStyle(fontWeight: isMyChoice ? FontWeight.bold : FontWeight.normal)),
                          if(hasVoted) Text("%${(percent * 100).toInt()} ($voteCount)"), 
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
        _buildActionItem(Icons.info_rounded, "Ev Bilgi", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeInfoScreen()));
        }),
        _buildActionItem(Icons.notifications_active, "Duyuru", () {}),
      ],
    );
  }

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
            Text(count, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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