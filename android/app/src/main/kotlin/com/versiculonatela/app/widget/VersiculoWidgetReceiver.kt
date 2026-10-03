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
            val (bg, fg) = widgetThemeColors(data.theme)
            val translucentBackground = Color.argb(
                100, Color.red(bg), Color.green(bg), Color.blue(bg)
            )
            views.setInt(R.id.widget_root, "setBackgroundColor", translucentBackground)
            views.setTextColor(R.id.widget_verse_text, fg)
            views.setTextColor(R.id.widget_verse_reference, fg)
            return views
        }

        fun widgetThemeColors(theme: String): Pair<Int, Int> = when (theme) {
            "escuro" -> Color.parseColor("#1B1D22") to Color.parseColor("#F3EFE4")
            "papel" -> Color.parseColor("#EDE3CC") to Color.parseColor("#3A3120")
            "gradiente" -> Color.parseColor("#3A2E55") to Color.parseColor("#FBF3E7")
            "elegante" -> Color.parseColor("#12141A") to Color.parseColor("#D9A857")
            "ceu" -> Color.parseColor("#2B3A55") to Color.parseColor("#FBFAF6")
            else -> Color.parseColor("#F7F4EC") to Color.parseColor("#20242B")
        }
    }
}
