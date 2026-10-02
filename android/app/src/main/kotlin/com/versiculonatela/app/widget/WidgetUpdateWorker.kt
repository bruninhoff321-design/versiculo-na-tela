package com.versiculonatela.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.JsonReader
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.ExistingPeriodicWorkPolicy
import java.util.concurrent.TimeUnit
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.InputStreamReader
import kotlin.random.Random

/**
 * Agendamento da PREFERÊNCIA de atualização (seção 5 do briefing).
 *
 * IMPORTANTE — isto é só o melhor esforço permitido pela plataforma:
 * o WorkManager tem um intervalo mínimo de 15 minutos para trabalho
 * periódico, e o Android pode atrasar a execução por Doze Mode / App
 * Standby / economia de bateria. Por isso a tela de Ajustes (seção 6)
 * mostra "aproximadamente", nunca um horário exato garantido.
 *
 * "Manual" (UpdateFrequency.manual) não agenda nenhum worker — o widget só
 * muda quando o usuário troca de versículo dentro do app.
 */
class WidgetUpdateWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            rotateVerse()
            val manager = AppWidgetManager.getInstance(applicationContext)
            val component = ComponentName(applicationContext, VersiculoWidgetReceiver::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val data = WidgetPreferences.read(applicationContext)
                for (id in ids) {
                    val views = VersiculoWidgetReceiver.buildRemoteViews(applicationContext, data)
                    manager.updateAppWidget(id, views)
                }
            }
            try {
                LockScreenWallpaper.update(applicationContext)
            } catch (_: Exception) {
                // O fabricante pode negar a troca; o widget ainda foi atualizado.
            }
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private fun rotateVerse() {
        val prefs = HomeWidgetPlugin.getData(applicationContext)
        val current = prefs.getString("verse_id", null)
        val recent = prefs.getString("recent_verse_ids", "")
            .orEmpty().split(',').filter { it.isNotBlank() }
        val noRepeat = prefs.getInt("no_repeat_count", 20).coerceAtLeast(0)
        val excluded = recent.takeLast(noRepeat).toSet() + current
        // Lê o arquivo em fluxo: a Bíblia completa não deve ocupar dezenas de
        // megabytes de memória toda vez que o Android atualizar o widget.
        val next = pickRandomVerse(excluded)
            ?: pickRandomVerse(setOfNotNull(current))
            ?: return
        val id = next.id
        val history = (recent + listOfNotNull(current)).takeLast(100)
        prefs.edit()
            .putString("verse_id", id)
            .putString("verse_text", next.text)
            .putString("verse_reference", "${next.book} ${next.chapter}:${next.verse}")
            .putString("recent_verse_ids", history.joinToString(","))
            .apply()
    }

    private data class VerseData(
        val id: String,
        val book: String,
        val chapter: Int,
        val verse: Int,
        val text: String,
    )

    private fun pickRandomVerse(excluded: Set<String?>): VerseData? {
        var chosen: VerseData? = null
        var eligibleCount = 0
        applicationContext.assets.open("flutter_assets/assets/verses.json").use { stream ->
            JsonReader(InputStreamReader(stream, Charsets.UTF_8)).use { reader ->
                reader.beginArray()
                while (reader.hasNext()) {
                    var id = ""
                    var book = ""
                    var chapter = 0
                    var verse = 0
                    var text = ""
                    reader.beginObject()
                    while (reader.hasNext()) {
                        when (reader.nextName()) {
                            "id" -> id = reader.nextString()
                            "book" -> book = reader.nextString()
                            "chapter" -> chapter = reader.nextInt()
                            "verse" -> verse = reader.nextInt()
                            "text" -> text = reader.nextString()
                            else -> reader.skipValue()
                        }
                    }
                    reader.endObject()
                    if (id !in excluded) {
                        eligibleCount++
                        if (Random.nextInt(eligibleCount) == 0) {
                            chosen = VerseData(id, book, chapter, verse, text)
                        }
                    }
                }
                reader.endArray()
            }
        }
        return chosen
    }

    companion object {
        private const val WORK_NAME = "versiculo_widget_refresh"

        // [minutes] deve ser >= 15 (mínimo do WorkManager); use null para cancelar (modo manual).
        fun schedule(context: Context, minutes: Int?) {
            val workManager = WorkManager.getInstance(context)
            if (minutes == null) {
                workManager.cancelUniqueWork(WORK_NAME)
                return
            }
            val effectiveMinutes = minutes.coerceAtLeast(15)
            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                effectiveMinutes.toLong(), TimeUnit.MINUTES,
            ).build()
            workManager.enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request,
            )
        }
    }
}
