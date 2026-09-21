package com.versiculonatela.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import com.versiculonatela.app.R

/**
 * Widget da tela inicial (seções 3 e 27 do briefing) — implementado com a
 * API clássica de App Widgets (AppWidgetProvider + RemoteViews). É a forma
 * mais estável e amplamente suportada de construir widgets Android, sem
 * depender de Jetpack Compose/Glance (evita problemas de compatibilidade de
 * versão entre Compose, Kotlin e o Android Gradle Plugin).
 *
 * Os dados (texto, referência, tema visual) são lidos de WidgetPreferences,
 * que é escrito pelo app Flutter através do plugin `home_widget` (ver
 * lib/data/widget_bridge/widget_sync_service.dart). Este widget NUNCA
 * decide qual versículo mostrar — ele só exibe o que o app já escolheu.
 */
class VersiculoWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = WidgetPreferences.read(context)
        for (appWidgetId in appWidgetIds) {
            val views = buildRemoteViews(context, data)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    companion object {
        fun buildRemoteViews(context: Context, data: WidgetData): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_versiculo)
            views.setTextViewText(R.id.widget_verse_text, "\u201c${data.verseText}\u201d")
            views.setTextViewText(R.id.widget_verse_reference, data.verseReference)

            val (bg, fg) = widgetThemeColors(data.theme)
            views.setInt(R.id.widget_root, "setBackgroundColor", bg)
            views.setTextColor(R.id.widget_verse_text, fg)
            views.setTextColor(R.id.widget_verse_reference, fg)
            return views
        }

        /** Paleta por tema visual — precisa espelhar
