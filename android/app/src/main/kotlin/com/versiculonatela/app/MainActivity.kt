package com.versiculonatela.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import com.versiculonatela.app.widget.LockScreenWallpaper
import com.versiculonatela.app.widget.VersiculoWidgetReceiver
import com.versiculonatela.app.widget.WidgetUpdateWorker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.versiculonatela.app/widget_scheduler"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pinWidget" -> {
                        try {
                            val manager = AppWidgetManager.getInstance(applicationContext)
                            val requested = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                manager.isRequestPinAppWidgetSupported &&
                                manager.requestPinAppWidget(
                                    ComponentName(applicationContext, VersiculoWidgetReceiver::class.java),
                                    null,
                                    null,
                                )
                            result.success(requested)
                        } catch (error: Exception) {
                            result.error("pin_failed", error.message, null)
                        }
                    }
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
