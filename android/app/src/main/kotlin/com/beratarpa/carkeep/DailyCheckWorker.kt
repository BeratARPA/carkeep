package com.beratarpa.carkeep

import android.content.Context
import android.util.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Surussuz donem yedegi (K-12, 01-spec 7.2). Kendini yeniden planlayan tek
 * seferlik is; hedef saat 19:00.
 *
 * T05 kapsaminda yalnizca planlama var (`scheduleDailyWorker` kanal metodu icin).
 * Kosul mantigi (`runOnce`) T14'te eklenir.
 */
class DailyCheckWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {

    override fun doWork(): Result {
        runOnce(applicationContext)
        schedule(applicationContext)
        return Result.success()
    }

    companion object {
        const val UNIQUE = "daily_check"
        const val TARGET_HOUR = 19
        private const val TAG = "CarKeep"

        /** 01-spec 7.2. T14'te doldurulacak. */
        fun runOnce(ctx: Context) {
            Log.d(TAG, "DailyCheckWorker.runOnce: T14'te uygulanacak")
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
    }
}
