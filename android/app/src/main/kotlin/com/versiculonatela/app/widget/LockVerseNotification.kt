package com.versiculonatela.app.widget

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.versiculonatela.app.MainActivity
import com.versiculonatela.app.R
import es.antonborri.home_widget.HomeWidgetPlugin

/** Atualiza o versículo silencioso quando o WorkManager troca o widget sem abrir o app. */
object LockVerseNotification {
    private const val CHANNEL_ID = "versiculo_no_bloqueio"
    private const val NOTIFICATION_ID = 1002

    fun update(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        if (!prefs.getBoolean("lock_screen_notification_enabled", false)) return
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) return

        val data = WidgetPreferences.read(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Versículo na tela de bloqueio", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Exibe o versículo sem som ou vibração"
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(channel)
        }

        val intent = PendingIntent.getActivity(
            context, 1002, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(data.verseReference)
            .setContentText(data.verseText)
            .setStyle(Notification.BigTextStyle().bigText(data.verseText))
            .setContentIntent(intent)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(Notification.PRIORITY_LOW)
            .setDefaults(0)
            .setSound(null)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }
}
