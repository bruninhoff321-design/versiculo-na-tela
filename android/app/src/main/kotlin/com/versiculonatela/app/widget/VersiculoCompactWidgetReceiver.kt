package com.versiculonatela.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.versiculonatela.app.MainActivity
import com.versiculonatela.app.R

/** Versão pequena para launchers e para o LockStar, quando disponível. */
class VersiculoCompactWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = WidgetPreferences.read(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildRemoteViews(context, data))
        }
    }

    companion object {
        fun buildRemoteViews(context: Context, data: WidgetData): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_versiculo_compact)
            views.setTextViewText(R.id.compact_verse_text, "“" + data.verseText + "”")
            views.setTextViewText(R.id.compact_verse_reference, data.verseReference)
            views.setContentDescription(
                R.id.compact_widget_root,
                data.verseText + " " + data.verseReference,
            )
            views.setInt(R.id.compact_widget_root, "setBackgroundColor", Color.TRANSPARENT)
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.compact_widget_root, pendingIntent)
            return views
        }
    }
}
