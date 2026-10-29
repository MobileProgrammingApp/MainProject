import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/login_screen.dart';
import 'app_theme.dart';

/// Oturum token'ının tek erişim noktası.
///
/// Token şifreli depolamada (Android Keystore) tutulur. 1.0.2 ve öncesinde
/// SharedPreferences'ta düz metin duruyordu; ilk okumada buraya taşınır ve
/// eski kopyası silinir, böylece güncelleyen kullanıcı oturumdan düşmez.
class Session {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'api_token';
  // Token bu cihaza özel mi (giriş/yenileme ile alındı)? Yoksa 1.0.2'den
  // taşınan, evdeki tüm cihazların paylaştığı token mı? Bkz. ApiService.renewSharedToken.
  static const _deviceTokenKey = 'api_token_is_device';

  /// MaterialApp'e verilir; oturum düşünce ekran bağlamı olmadan giriş
  /// ekranına dönebilmek ve mesaj gösterebilmek için.
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static String? _cachedToken;
  static bool _expiring = false;

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      _cachedToken = await _storage.read(key: _tokenKey);
    } catch (e) {
      // Anahtar okunamadı (ör. yedekten geri yüklenmiş cihaz): temiz başla
      debugPrint("Güvenli depolama okunamadı: $e");
      await _storage.deleteAll();
    }

    if (_cachedToken == null) {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_tokenKey);
      if (legacy != null && legacy.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: legacy);
        await prefs.remove(_tokenKey);
        _cachedToken = legacy;
      }
    }
    return _cachedToken;
  }

  /// Giriş veya yenileme ile alınan, bu cihaza özel token'ı kaydeder.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _deviceTokenKey, value: '1');
    _cachedToken = token;
    _expiring = false;
  }

  /// Token var ama bu cihaza özel değil (eski sürümden taşınan ortak token).
  static Future<bool> hasSharedToken() async {
    if (await getToken() == null) return false;
    try {
      return await _storage.read(key: _deviceTokenKey) != '1';
    } catch (_) {
      return true;
    }
  }

  /// Token'ı ve cihazdaki tüm oturum verilerini (ev, seçili üye vb.) siler.
  /// Tema seçimi oturuma değil cihaza ait olduğu için korunur.
  static Future<void> clear() async {
    _cachedToken = null;
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(AppTheme.modeKey);
    await prefs.clear();
    if (themeMode != null) await prefs.setString(AppTheme.modeKey, themeMode);
  }

  /// Sunucu token'ı reddetti (şifre değişti/sıfırlandı, oturum kapatıldı).
  /// Aynı anda birden fazla istek 401 alabileceği için tek sefer çalışır.
  static Future<void> expire() async {
    if (_expiring) return;
    _expiring = true;

    await clear();

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      // Uygulama henüz açılmadı (main içindeyiz); main token olmadığını görüp
      // giriş ekranıyla başlar. Sonraki 401'ler yine yönlendirebilsin.
      _expiring = false;
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text("Oturumunuz sona erdi, lütfen tekrar giriş yapın.")),
    );
  }
}
