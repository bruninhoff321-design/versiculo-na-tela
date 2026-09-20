package com.versiculonatela.app.widget

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * Ponto de entrada do sistema Android para o widget (referenciado no
 * AndroidManifest.xml e usado pelo home_widget para pedir refresh via
 * HomeWidget.updateWidget(androidName: ...) do lado Flutter).
 */
class VersiculoWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = VersiculoWidget()
}
