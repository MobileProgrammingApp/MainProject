import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
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

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

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

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (await _isEnabled()) {
        await _registerToken(token);
      }
    });

    if (await _isEnabled()) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    }
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
    );
  }

  /// Bildirim aç/kapa switch'i tarafından çağrılır: kapatınca sunucudaki
  /// fcm_token'ı boşaltır (bu üyeye artık bildirim gönderilmez), açınca
  /// güncel token'ı yeniden kaydeder.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);

    if (enabled) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } else {
      await _registerToken('');
    }
  }

  static Future<void> _registerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('saved_member_id');
    if (memberId == null) return;

    final apiToken = prefs.getString('api_token') ?? '';

    try {
      await http.post(
        Uri.parse("${ApiService.baseUrl}/update_member_token.php"),
        body: {
          "api_token": apiToken,
          "member_id": memberId.toString(),
          "fcm_token": token,
        },
      );
    } catch (e) {
      print("FCM token kaydı başarısız: $e");
    }
  }
}
