package com.beratarpa.carkeep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

/**
 * K-30: Activity Recognition gecisleri. Karar vermez, tek is prefs'e zaman
 * damgasi yazmak — `onReceive` bir SharedPreferences yazimindan ibaret
 * (CLAUDE.md: 5 sn kurali).
 *
 * `IN_VEHICLE` cikisi da damga gunceller: kopma cikistan hemen sonra gelir ve
 * cikis, girisin gorulmedigi durumda da surusun kanitidir.
 */
class MotionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return

        var latest = -1L
        for (event in result.transitionEvents) {
            if (event.activityType != DetectedActivity.IN_VEHICLE) continue
            // `elapsedRealtimeNanos` acilistan beri gecen sure; duvar saatine
            // cevriliyor cunku prefs'teki diger damgalar `currentTimeMillis`.
            val at = wallClock(event.elapsedRealTimeNanos)
            if (at > latest) latest = at
        }
        if (latest <= 0L) return

        EnginePrefs(context).lastInVehicleAt = latest
        Log.d(TAG, "IN_VEHICLE transition at $latest")
    }

    private fun wallClock(elapsedRealtimeNanos: Long): Long {
        val bootAt = System.currentTimeMillis() - android.os.SystemClock.elapsedRealtime()
        return bootAt + elapsedRealtimeNanos / 1_000_000L
    }

    companion object {
        private const val TAG = "CarKeep"
    }
}
