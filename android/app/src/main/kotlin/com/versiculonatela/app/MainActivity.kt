package com.versiculonatela.app

import com.versiculonatela.app.widget.WidgetUpdateWorker
import com.versiculonatela.app.widget.LockScreenWallpaper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Único código nativo Android que o Flutter chama diretamente: agendar (ou
 * cancelar) a atualização periódica do widget via WorkManager, conforme a
 * preferência de frequência escolhida em Ajustes (seção 5 do briefing).
 * Ver lib/data/widget_bridge/native_scheduler.dart do lado Dart.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.versiculonatela.app/widget_scheduler"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val minutes = call.argument<Int>("minutes")
                        WidgetUpdateWorker.schedule(applicationContext, minutes)
                        result.success(null)
                    }
                    "lockWallpaperEnabled" -> result.success(
                        LockScreenWallpaper.isEnabled(applicationContext)
                    )
                    "setLockWallpaperEnabled" -> {
                        try {
                            LockScreenWallpaper.setEnabled(
                                applicationContext,
                                call.argument<Boolean>("enabled") == true
                            )
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("wallpaper_failed", error.message, null)
                        }
                    }
                    "refreshLockWallpaper" -> {
                        try {
                            LockScreenWallpaper.update(applicationContext)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("wallpaper_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
