package com.versiculonatela.app.widget

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import es.antonborri.home_widget.HomeWidgetPlugin

/** Draws the selected verse locally; no network or background Flutter engine. */
object LockScreenWallpaper {
    fun isEnabled(context: Context): Boolean =
        HomeWidgetPlugin.getData(context).getBoolean("lock_wallpaper_enabled", false)

    fun setEnabled(context: Context, enabled: Boolean) {
        HomeWidgetPlugin.getData(context).edit()
            .putBoolean("lock_wallpaper_enabled", enabled).apply()
        if (enabled) update(context)
    }

    fun update(context: Context) {
        if (!isEnabled(context) || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        val data = WidgetPreferences.read(context)
        val metrics = context.resources.displayMetrics
        val width = metrics.widthPixels.coerceAtLeast(720)
        val height = metrics.heightPixels.coerceAtLeast(1280)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f, 0f, width.toFloat(), height.toFloat(),
                Color.rgb(9, 32, 57), Color.rgb(83, 49, 43), Shader.TileMode.CLAMP
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), background)

        val margin = width * 0.09f
        val available = (width - 2 * margin).toInt()
        val versePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = width * if (data.verseText.length > 180) 0.047f else 0.057f
            typeface = android.graphics.Typeface.create("serif", android.graphics.Typeface.NORMAL)
        }
        val verse = StaticLayout.Builder.obtain(
            "“${data.verseText}”", 0, data.verseText.length + 2, versePaint, available
        ).setAlignment(Layout.Alignment.ALIGN_CENTER).setLineSpacing(8f, 1f).build()
        val top = ((height - verse.height) * 0.50f).coerceAtLeast(height * 0.30f)
        canvas.save()
        canvas.translate(margin, top)
        verse.draw(canvas)
        canvas.restore()

        val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(247, 207, 128)
            textSize = width * 0.046f
            textAlign = Paint.Align.CENTER
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
        }
        canvas.drawText(data.verseReference, width / 2f, top + verse.height + height * 0.055f, label)
        label.textSize = width * 0.031f
        label.color = Color.rgb(235, 223, 203)
        canvas.drawText("VERSÍCULO NA TELA", width / 2f, height * 0.88f, label)

        try {
            WallpaperManager.getInstance(context).setBitmap(
                bitmap, null, false, WallpaperManager.FLAG_LOCK
            )
        } finally {
            bitmap.recycle()
        }
    }
}
