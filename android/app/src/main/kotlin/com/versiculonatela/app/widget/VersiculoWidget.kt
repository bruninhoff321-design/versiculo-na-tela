package com.versiculonatela.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontStyle
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * Widget da tela inicial implementado com Jetpack Glance — a API oficial e
 * atual do Android para App Widgets (substitui os antigos RemoteViews
 * manuais). Este único GlanceAppWidget se adapta a três tamanhos
 * (pequeno/médio/grande, seção 3 do briefing) via SizeMode.Responsive, sem
 * precisar de três classes de widget separadas.
 *
 * IMPORTANTE: dentro de um GlanceAppWidget só podem ser usados os
 * composables de `androidx.glance.layout.*` / `androidx.glance.text.*`
 * (Box, Column, Row, Text...) — NÃO os de `androidx.compose.foundation.*`.
 * O Glance renderiza para RemoteViews por baixo, então não é uma árvore de
 * Compose UI comum.
 *
 * Os dados (texto, referência, tema visual) são lidos de WidgetPreferences,
 * que é escrito pelo app Flutter através do plugin `home_widget` (ver
 * lib/data/widget_bridge/widget_sync_service.dart). Este widget NUNCA
 * decide qual versículo mostrar — ele só exibe o que o app já escolheu.
 */
class VersiculoWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Responsive(
        setOf(SMALL_SIZE, MEDIUM_SIZE, LARGE_SIZE)
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = WidgetPreferences.read(context)
        provideContent {
            VersiculoWidgetContent(data)
        }
    }

    companion object {
        val SMALL_SIZE = DpSize(110.dp, 110.dp)
        val MEDIUM_SIZE = DpSize(250.dp, 110.dp)
        val LARGE_SIZE = DpSize(250.dp, 250.dp)
    }
}

@Composable
private fun VersiculoWidgetContent(data: WidgetData) {
    val size = LocalSize.current
    val (bg, fg) = widgetThemeColors(data.theme)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(bg)
            .padding(16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "\u201c${data.verseText}\u201d",
                maxLines = if (size.height > MediumHeightThreshold) 8 else 3,
                style = TextStyle(
                    color = ColorProvider(fg),
                    fontSize = if (size.width > 200.dp) 15.sp else 12.sp,
                    fontStyle = FontStyle.Italic,
                    textAlign = TextAlign.Center,
                ),
            )
            Text(
                text = data.verseReference,
                style = TextStyle(
                    color = ColorProvider(fg),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                ),
            )
        }
    }
}

private val MediumHeightThreshold = 180.dp

/** Paleta por tema visual — precisa espelhar AppTheme.widgetThemeColors (Dart) e widgetThemeColors (Swift). */
private fun widgetThemeColors(theme: String): Pair<Color, Color> = when (theme) {
    "escuro" -> Color(0xFF1B1D22) to Color(0xFFF3EFE4)
    "papel" -> Color(0xFFEDE3CC) to Color(0xFF3A3120)
    "gradiente" -> Color(0xFF3A2E55) to Color(0xFFFBF3E7)
    "elegante" -> Color(0xFF12141A) to Color(0xFFD9A857)
    "ceu" -> Color(0xFF2B3A55) to Color(0xFFFBFAF6)
    else -> Color(0xFFF7F4EC) to Color(0xFF20242B) // "claro"
}
