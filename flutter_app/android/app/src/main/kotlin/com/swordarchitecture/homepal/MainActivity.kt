package com.swordarchitecture.homepal

import android.app.UiModeManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ayarlar > Görünüm'de seçilen tema Android'e de bildirilir (lib/core/app_theme.dart):
        // Android 12+ açılış ekranı telefonun değil uygulamanın temasıyla çizilir. Manifest'te
        // configChanges "uiMode" içerdiği için bu değişiklik Activity'yi yeniden başlatmaz.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "homepal/theme").setMethodCallHandler { call, result ->
            if (call.method != "setNightMode") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val mode = when (call.arguments as? String) {
                    "light" -> UiModeManager.MODE_NIGHT_NO
                    "dark" -> UiModeManager.MODE_NIGHT_YES
                    else -> UiModeManager.MODE_NIGHT_AUTO // telefonun ayarına uy
                }
                getSystemService(UiModeManager::class.java).setApplicationNightMode(mode)
            }
            result.success(null)
        }
    }
}
