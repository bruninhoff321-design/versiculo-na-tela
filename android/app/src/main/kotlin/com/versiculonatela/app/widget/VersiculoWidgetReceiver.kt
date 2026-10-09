package com.versiculonatela.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import com.versiculonatela.app.R

/** Exibe o versículo escolhido pelo app ou pelo atualizador nativo. */
class VersiculoWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = WidgetPreferences.read(context)
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, buildRemoteViews(context, data))
        }
    }

    companion object {
        fun buildRemoteViews(context: Context, data: WidgetData): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_versiculo)
            views.setTextViewText(R.id.widget_verse_text, "\u201c${data.verseText}\u201d")
            views.setTextViewText(R.id.widget_verse_reference, data.verseReference)
            // O texto flutua sobre o wallpaper, mesmo para quem havia salvo
            // um tema antigo que desenhava uma placa atrás do versículo.
            views.setInt(R.id.widget_root, "setBackgroundColor", Color.TRANSPARENT)
            views.setTextColor(R.id.widget_verse_text, Color.WHITE)
            views.setTextColor(R.id.widget_verse_reference, Color.WHITE)
            return views
        }
    }
}
