package com.beratarpa.carkeep

import android.content.Context
import android.util.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Surussuz donem yedegi (K-12, 01-spec 7.2). Kendini yeniden planlayan tek
 * seferlik is; hedef saat 19:00 (WorkManager esnekligi kadar kayabilir).
 *
 * Karar `ReminderEngine.evaluateFallback` icinde (saf, JVM testli); burada
 * yalnizca yan etkiler.
 */
class DailyCheckWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {

    override fun doWork(): Result {
        runOnce(applicationContext)
        // Her calismada bir sonraki 19:00'a yeniden planlanir.
        schedule(applicationContext)
        return Result.success()
    }

    companion object {
        const val UNIQUE = "daily_check"
        const val TARGET_HOUR = 19
        private const val TAG = "CarKeep"

        /** 01-spec 7.2. `debugRunDailyWorker` da bunu cagirir. */
        fun runOnce(ctx: Context) {
            val prefs = EnginePrefs(ctx)
            val snapshot = Snapshot.parse(prefs.snapshotJson)
            val today = DayKey.today()
            val decision = ReminderEngine.evaluateFallback(
                snapshot = snapshot,
                state = ReminderEngine.readState(prefs),
                today = today,
                lastTripDay = lastTripDay(prefs),
            )

            when (decision) {
                is ReminderEngine.FallbackDecision.Skip -> {
                    Log.d(TAG, "fallback skipped: ${decision.note}")
                    return
                }

                is ReminderEngine.FallbackDecision.Notify -> {
                    Notifications.ensureChannel(ctx)
                    val shown = Notifications.showOverdue(
                        ctx,
                        decision.names,
                        daysNoDrive = decision.daysNoDrive,
                    )
                    if (!shown) {
                        // Denetim md. 4 / K-25: basilamadiysa durum da yazilmaz.
                        Log.d(TAG, "fallback not shown: notifications disabled")
                        return
                    }
                    prefs.prevLastNotifiedDay = prefs.lastNotifiedDay
                    prefs.lastNotifiedDay = today
                    // K-20: `last_notified_at` YAZILMAZ. O alanin tek isi K-06'nin
                    // grace penceresini olcmek; yedek bildirimin bir kopmayla
                    // ilgisi yok, pencere acmamali.
                    prefs.appendPendingEvent(
                        JSONObject()
                            .put("type", "fallback")
                            .put("at", System.currentTimeMillis())
                            .put("overdueCount", decision.names.size),
                    )
                    Log.d(TAG, "fallback shown: ${decision.names.size} overdue")
                }
            }
        }

        fun schedule(ctx: Context) {
            val now = Calendar.getInstance()
            val target = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, TARGET_HOUR)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (!after(now)) add(Calendar.DAY_OF_MONTH, 1)
            }
            val delay = target.timeInMillis - now.timeInMillis
            val req = OneTimeWorkRequestBuilder<DailyCheckWorker>()
                .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                .build()
            WorkManager.getInstance(ctx)
                .enqueueUniqueWork(UNIQUE, ExistingWorkPolicy.REPLACE, req)
            Log.d(TAG, "daily check scheduled in ${delay / 60_000} min")
        }

        /** Son kopmanin gunu; hic kopma gorulmediyse null. */
        private fun lastTripDay(prefs: EnginePrefs): String? {
            val raw = prefs.lastTripJson ?: return null
            val millis = try {
                JSONObject(raw).optLong("disconnectedAt", -1L)
            } catch (e: Exception) {
                -1L
            }
            return if (millis > 0) DayKey.of(millis) else null
        }
    }
}
