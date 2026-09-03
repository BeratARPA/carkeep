package com.beratarpa.carkeep

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationManagerCompat

/**
 * Bildirim kanali ve iptal (01-spec 3.8).
 *
 * T05 kapsaminda yalnizca kanal kurulumu ve iptal var; bildirimi basan
 * `showOverdue` T12'de eklenir.
 */
object Notifications {

    const val CHANNEL_ID = "reminders"
    const val NOTIF_ID = 1001
    const val EXTRA_ACTION = "carkeep_action"
    const val ACTION_OVERDUE = "overdue"
    const val ACTION_SNOOZE = "com.beratarpa.carkeep.SNOOZE"

    /** Idempotent. */
    fun ensureChannel(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "CarKeep hatırlatmaları",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Arabadan inince gecikmiş kontroller"
            enableVibration(true)
        }
        nm.createNotificationChannel(channel)
    }

    fun cancel(ctx: Context) {
        NotificationManagerCompat.from(ctx).cancel(NOTIF_ID)
    }

    /** Kullanici kanali kapatmis mi (07 8, uyari seridi icin). */
    fun areNotificationsEnabled(ctx: Context): Boolean {
        if (!NotificationManagerCompat.from(ctx).areNotificationsEnabled()) return false
        val nm = ctx.getSystemService(NotificationManager::class.java) ?: return true
        val channel = nm.getNotificationChannel(CHANNEL_ID) ?: return true
        return channel.importance != NotificationManager.IMPORTANCE_NONE
    }
}
