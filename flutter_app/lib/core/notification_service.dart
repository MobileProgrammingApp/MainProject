import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Uygulama arka plandayken/kapalıyken FCM bildirimi sistem tepsisinde
  // otomatik gösterilir, burada ekstra bir şey yapmaya gerek yok.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'homepal_default_channel',
    'Homepal Bildirimleri',
    description: 'Görev ve anket bildirimleri',
    importance: Importance.high,
  );

  /// Bildirime dokunulunca açılacak ekran ('home' / 'chores' / 'shopping').
  /// Sunucu bunu bildirimin "screen" verisinde gönderir; AppScaffold dinler.
  static final ValueNotifier<String?> requestedScreen = ValueNotifier(null);

  static void _open(String? screen) {
    if (screen != null && screen.isNotEmpty) requestedScreen.value = screen;
  }

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    // Uygulama açıkken gösterdiğimiz bildirime dokunulursa
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Uygulama arka plandayken / kapalıyken bildirime dokunulursa
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _open(message.data['screen']));
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _open(initialMessage.data['screen']);

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (await _isEnabled()) {
        await _registerToken(token);
      }
    });

    // Cihaz token'ını sunucuya kaydet. Ağ isteği olduğu için beklenmez:
    // yavaş internette açılış ekranında takılı kalınmasın.
    unawaited(syncToken().catchError((Object e) {
      debugPrint("FCM token kaydı başarısız: $e");
      return false;
    }));
  }

  static Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    if (!await _isEnabled()) return;

    const androidDetails = AndroidNotificationDetails(
      'homepal_default_channel',
      'Homepal Bildirimleri',
      channelDescription: 'Görev ve anket bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['screen'],
    );
  }

  /// Bildirim aç/kapa switch'i tarafından çağrılır: kapatınca sunucudaki
  /// fcm_token'ı boşaltır (bu üyeye artık bildirim gönderilmez), açınca
  /// güncel token'ı yeniden kaydeder.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    await syncToken();
  }

  /// Seçili üyenin sunucudaki cihaz token'ını bildirim ayarına göre günceller.
  /// "Ben Kimim?" profili değişince de çağrılır.
  static Future<bool> syncToken() async {
    if (!await _isEnabled()) {
      return _registerToken('');
    }
    final token = await FirebaseMessaging.instance.getToken();
    return token != null && await _registerToken(token);
  }

  static Future<bool> _registerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('saved_member_id');
    if (memberId == null) return false;

    final ok = await ApiService.updateMemberToken(memberId, token);
    if (!ok) debugPrint("FCM token kaydı başarısız");
    return ok;
  }
}
