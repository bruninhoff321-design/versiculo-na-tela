package com.versiculonatela.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.ExistingPeriodicWorkPolicy
import java.util.concurrent.TimeUnit

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
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
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
