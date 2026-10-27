import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_scaffold.dart';
import '../../core/app_theme.dart';
import '../../core/crash_reporting.dart';
import '../../core/notification_service.dart';
import '../../core/session.dart';
import '../../core/widgets/homepal_mark.dart';
import '../../firebase_options.dart';
import '../auth/login_screen.dart';

/// Açılış ekranı. İlk karesi Android'in yerel açılış ekranıyla birebir aynıdır
/// (aynı arka plan, aynı boyut ve konumda amblem); ardından amblem yukarı
/// kayıp küçülür, "HomePal" yazısı belirir ve ev göz kırpar.
/// Uygulamanın hazırlığı (Firebase, bildirimler, oturum) bu sırada yapılır.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  bool _showProgress = false;
  bool _isPrepared = false;

  late final Animation<double> _markMove = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.1, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _title = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    final prepared = _prepare();
    // Animasyon ilk kare çizildikten sonra başlar: Flutter motorunun açılması
    // yavaş cihazlarda saniyeler sürebilir; süre önceden saymaya başlarsa
    // animasyon hiç görünmeden giriş ekranına geçiliyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play(prepared));
  }

  @override
  void dispose() {
    _intro.dispose();
    _blink.dispose();
    super.dispose();
  }

  Future<void> _play(Future<Widget> prepared) async {
    // Android'in açılış ekranı solarken animasyon kaçmasın
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    await _intro.forward();
    if (!mounted) return;
    // Yazı yerine oturunca bir kez göz kırp
    await _blink.forward();
    if (!mounted) return;
    await _blink.reverse();

    // Hazırlık hâlâ sürüyorsa (yavaş internet) bekleme göstergesi çıksın
    if (!_isPrepared && mounted) setState(() => _showProgress = true);

    final next = await prepared;
    if (!mounted) return; // Oturum bu sırada düştüyse Session.expire giriş ekranına geçti

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Uygulamayı hazırlar ve açılacak ilk ekranı döndürür. Hata fırlatmaz.
  Future<Widget> _prepare() async {
    try {
      return await _prepareSteps();
    } catch (e) {
      debugPrint("Açılış hazırlığı başarısız: $e");
      return const LoginScreen();
    } finally {
      _isPrepared = true;
    }
  }

  Future<Widget> _prepareSteps() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await CrashReporting.initialize();
      await NotificationService.initialize();
    } catch (e) {
      // Bildirimler çalışmasa da uygulama açılsın (ör. Google Play servisleri yok)
      debugPrint("Firebase başlatılamadı: $e");
    }

    // Eski sürümden kalan ortak token'ı bu cihaza özel bir token'la değiştir
    // (eski sürümden gelen token bu sırada şifreli depoya da taşınır).
    await ApiService.renewSharedToken();

    // Ev ve oturum token'ı varsa kullanıcı giriş yapmış demektir: ana ekran açılır.
    // "Ben Kimim?" profili henüz seçilmediyse panel bunu ayrıca ister.
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getInt('saved_house_id');
    final token = await Session.getToken();
    return (houseId == null || token == null) ? const LoginScreen() : AppScaffold(houseId: houseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _blink]),
        builder: (context, _) {
          // Tüm ekranı kaplar: amblem, yerel açılış ekranındaki gibi tam ortada başlar
          return Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox.expand(),
              // Amblem: yerel açılış ekranıyla aynı yerde başlar, sonra yukarı kayıp küçülür
              Transform.translate(
                offset: Offset(0, -50 * _markMove.value),
                child: Transform.scale(
                  scale: 1 - 0.3 * _markMove.value,
                  child: BrandHero(tag: BrandHero.mark, child: HomePalMark(blink: _blink.value)),
                ),
              ),
              // Yazılar amblemin altına, aşağıdan kayarak gelir
              Transform.translate(
                offset: Offset(0, 40 + 12 * (1 - _title.value)),
                child: Opacity(
                  opacity: _title.value,
                  child: const BrandHero(tag: BrandHero.wordmark, child: HomePalWordmark()),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 80 + 10 * (1 - _tagline.value)),
                child: Opacity(
                  opacity: _tagline.value,
                  child: const BrandHero(
                    tag: BrandHero.tagline,
                    child: Text("Evin ortak asistanı", style: AppStyles.listTileSubtitle),
                  ),
                ),
              ),
              Positioned(
                bottom: 64,
                child: AnimatedOpacity(
                  opacity: _showProgress ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
