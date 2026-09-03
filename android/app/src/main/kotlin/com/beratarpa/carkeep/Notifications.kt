package com.beratarpa.carkeep

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Bildirim kanali, basma ve iptal (01-spec 3.8). Metinler [NotificationText].
 */
object Notifications {

    const val CHANNEL_ID = "reminders"
    const val NOTIF_ID = 1001
    const val EXTRA_ACTION = "carkeep_action"
    const val ACTION_OVERDUE = "overdue"
    const val ACTION_SNOOZE = "com.beratarpa.carkeep.SNOOZE"

    private const val TAG = "CarKeep"
    private const val REQ_OPEN = 1
    private const val REQ_SNOOZE = 2

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

    /**
     * `names` bos olabilir (`onlyOverdue=false` modu). `daysNoDrive` yalniz yedek
     * bildirimde (T14).
     *
     * **Donus: bildirim gercekten basildi mi** (denetim md. 4). Cagiran taraf
     * `last_notified_*` durumunu yalniz `true` iken yazar; aksi halde izin
     * sonradan verilse de o gun bildirim gelmezdi.
     */
    fun showOverdue(ctx: Context, names: List<String>, daysNoDrive: Int? = null): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.d(TAG, "showOverdue skipped: POST_NOTIFICATIONS not granted")
            return false
        }
        // Kanali kapatmak calisma zamani iznini geri almiyor: izin verili
        // gorunurken `notify` sessizce dusuyor ve hata da atmiyor. Bu kontrol
        // olmadan motor basilmamis bir bildirimi basilmis sayar ve
        // `once_per_day` o gunu yakar (denetim md. 4'un ikinci yarisi, 07 8).
        if (!areNotificationsEnabled(ctx)) {
            Log.d(TAG, "showOverdue skipped: notifications disabled")
            return false
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val openIntent = Intent(ctx, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_ACTION, ACTION_OVERDUE)
        }
        val openPi = PendingIntent.getActivity(ctx, REQ_OPEN, openIntent, flags)
        val snoozePi = PendingIntent.getBroadcast(
            ctx,
            REQ_SNOOZE,
            Intent(ctx, NotifActionReceiver::class.java).setAction(ACTION_SNOOZE),
            flags,
        )

        val notification = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_carkeep)
            .setContentTitle(NotificationText.title(names.size))
            .setContentText(NotificationText.contentText(names, daysNoDrive))
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(NotificationText.big(names, daysNoDrive)),
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openPi)
            .addAction(0, "Aç", openPi)
            .addAction(0, "Yarın", snoozePi)
            .build()

        return try {
            val manager = NotificationManagerCompat.from(ctx)
            // Sabit id (1001) + `setOnlyAlertOnce`: tepside duran eski bildirim
            // varsa yenisi "guncelleme" sayilir ve Android sesi, titresimi ve
            // heads-up'i bastirir. Kullanici dunku bildirimi silmediyse bugunku
            // hatirlatma sessizce tepsiye duserdi; onun icin once iptal.
            manager.cancel(NOTIF_ID)
            manager.notify(NOTIF_ID, notification)
            Log.d(TAG, "notification shown: ${names.size} overdue")
            true
        } catch (e: SecurityException) {
            Log.d(TAG, "notify failed: ${e.message}")
            false
        }
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
