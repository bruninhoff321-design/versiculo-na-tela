package com.versiculonatela.app.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Lê os dados que o app Flutter grava através do plugin `home_widget`
 * (lib/data/widget_bridge/widget_sync_service.dart -> HomeWidget.saveWidgetData).
 * `HomeWidgetPlugin.getData(context)` devolve a mesma SharedPreferences que
 * o plugin usa do lado Flutter — não existe chamada de rede nem IPC extra
 * aqui, é leitura local direta, por isso o widget funciona offline
 * (seção 25 do briefing).
 */
data class WidgetData(
    val verseText: String,
    val verseReference: String,
    val theme: String,
)

object WidgetPreferences {
    private val FALLBACK = WidgetData(
        verseText = "Vinde a mim, todos os que estais cansados e sobrecarregados, e eu vos aliviarei.",
        verseReference = "Mateus 11:28",
        theme = "claro",
    )

    fun read(context: Context): WidgetData {
        val prefs = HomeWidgetPlugin.getData(context)
        return WidgetData(
            verseText = prefs.getString("verse_text", null) ?: FALLBACK.verseText,
            verseReference = prefs.getString("verse_reference", null) ?: FALLBACK.verseReference,
            theme = prefs.getString("widget_theme", null) ?: FALLBACK.theme,
        )
    }
}
