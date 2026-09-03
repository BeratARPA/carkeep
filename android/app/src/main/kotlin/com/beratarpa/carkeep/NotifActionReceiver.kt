package com.beratarpa.carkeep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject

/**
 * Bildirimdeki "Yarin" eylemi (K-13): o gun icin genel erteleme. Kayit
 * olusturmaz; madde ekranda gecikmis gorunmeye devam eder.
 */
class NotifActionReceiver : BroadcastReceiver() {

    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Notifications.ACTION_SNOOZE) return

        val prefs = EnginePrefs(ctx)
        val until = DayKey.plusDays(DayKey.today(), 1)
        prefs.globalSnoozeUntilDay = until
        // K-20 ile ayni gerekce: `last_notified_at`in tek isi K-06'nin grace
        // penceresini olcmek. Bildirim elle kapatildi, geri alinacak bir sey yok;
        // pencere acik kalirsa arabaya hemen binmek `last_notified_day`i geri alir.
        prefs.lastNotifiedAt = -1L
        Notifications.cancel(ctx)
        prefs.appendPendingEvent(
            JSONObject().put("type", "snooze").put("untilDay", until),
        )
        Log.d(TAG, "snoozed until $until")
    }

    companion object {
        private const val TAG = "CarKeep"
    }
}
