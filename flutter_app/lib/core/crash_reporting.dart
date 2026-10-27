import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Yakalanmamış hataları Firebase Crashlytics'e gönderir; böylece kullanıcının
/// telefonunda yaşanan çökmeler bize haber verilmeden kaybolmaz.
/// Firebase başlatıldıktan sonra çağrılmalı.
class CrashReporting {
  static Future<void> initialize() async {
    final crashlytics = FirebaseCrashlytics.instance;
    // Rapor yalnızca yayın sürümünden gider; debug/profile derlemelerdeki
    // hatalar yine konsolda görünür, panoyu kirletmez.
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    // Flutter'ın yakaladığı hatalar (ör. bir ekran çizilirken oluşanlar)
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    // Hiçbir yerde yakalanmayan asenkron hatalar
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
