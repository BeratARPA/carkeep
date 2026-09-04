package com.beratarpa.carkeep

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity

/**
 * K-30: "araba gercekten hareket etti mi?" kaniti. Activity Recognition
 * gecisleri (`IN_VEHICLE` giris/cikis) dinlenir; sonuc yalniz
 * `EnginePrefs.lastInVehicleAt` alanina yazilir.
 *
 * Hesap yapmaz (K-04); karar `ReminderEngine.evaluateDisconnect` icinde.
 * Play Services yoksa veya izin verilmediyse **sessizce kapali** kalir:
 * `motionUpdatesActive` false olur ve motor kontrolu atlar.
 */
object MotionTracker {

    private const val TAG = "CarKeep"
    private const val REQUEST_CODE = 2001

    const val ACTION_TRANSITION = "com.beratarpa.carkeep.ACTIVITY_TRANSITION"

    /** API 29+ calisma zamani izni; oncesinde Play Services'in kendi izni. */
    val PERMISSION: String = if (Build.VERSION.SDK_INT >= 29) {
        Manifest.permission.ACTIVITY_RECOGNITION
    } else {
        "com.google.android.gms.permission.ACTIVITY_RECOGNITION"
    }

    fun hasPermission(ctx: Context): Boolean =
        ctx.checkSelfPermission(PERMISSION) == PackageManager.PERMISSION_GRANTED

    /** Play Services kurulu ve guncel mi. Cihazda yoksa ozellik kapali kalir. */
    fun isAvailable(ctx: Context): Boolean =
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(ctx) ==
            ConnectionResult.SUCCESS

    /**
     * Abonelik kurar. Basarili olursa `motionUpdatesActive = true`.
     *
     * Kayit **asenkron** tamamlanir; `true` donmesi "istek gonderildi"
     * demektir. Basarisiz olursa bayrak geri false'a cekilir, motor da
     * kontrolu atlar (guvenli taraf).
     */
    fun start(ctx: Context): Boolean {
        val prefs = EnginePrefs(ctx)
        if (!isAvailable(ctx) || !hasPermission(ctx)) {
            prefs.motionUpdatesActive = false
            Log.d(TAG, "motion updates not started: available=${isAvailable(ctx)} perm=${hasPermission(ctx)}")
            return false
        }
        val transitions = listOf(
            ActivityTransition.Builder()
                .setActivityType(DetectedActivity.IN_VEHICLE)
                .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                .build(),
            ActivityTransition.Builder()
                .setActivityType(DetectedActivity.IN_VEHICLE)
                .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_EXIT)
                .build(),
        )
        return try {
            ActivityRecognition.getClient(ctx)
                .requestActivityTransitionUpdates(
                    ActivityTransitionRequest(transitions),
                    pendingIntent(ctx),
                )
                .addOnSuccessListener {
                    EnginePrefs(ctx).apply {
                        motionUpdatesActive = true
                        motionRegisteredBootAt = bootAt()
                    }
                    Log.d(TAG, "motion updates registered")
                }
                .addOnFailureListener { e ->
                    EnginePrefs(ctx).motionUpdatesActive = false
                    Log.d(TAG, "motion updates failed: ${e.message}")
                }
            true
        } catch (e: SecurityException) {
            prefs.motionUpdatesActive = false
            Log.d(TAG, "motion updates SecurityException")
            false
        }
    }

    /**
     * Karar anindaki gercek durum: bayrak **ve** izin.
     *
     * Bayrak tek basina yetmiyor. Kullanici izni sistem ayarlarindan geri
     * alirsa Play Services gecis gondermeyi keser, ama bayrak true kalir:
     * motor uygulama calismadan da calistigi icin (K-03) bunu hic ogrenemez ve
     * her surusu "hareket gormedim" sayip bildirimi sessizce yutar. Cihaz
     * testinde bulundu.
     *
     * Izin gitmisse bayrak burada duzeltiliyor; tek bir prefs yazimi, receiver
     * icin sorun degil.
     */
    fun isActive(ctx: Context): Boolean {
        val prefs = EnginePrefs(ctx)
        if (!prefs.motionUpdatesActive) return false
        if (!hasPermission(ctx)) {
            prefs.motionUpdatesActive = false
            Log.d(TAG, "motion permission revoked: updates marked inactive")
            return false
        }
        // K-34: Play Services abonelikleri yeniden baslatmada dusuyor.
        if (!ReminderEngine.sameBoot(prefs.motionRegisteredBootAt, bootAt())) {
            prefs.motionUpdatesActive = false
            Log.d(TAG, "device rebooted since registration: updates marked inactive")
            return false
        }
        return true
    }

    /** Acilis aninin duvar saati karsiligi. */
    private fun bootAt(): Long =
        System.currentTimeMillis() - android.os.SystemClock.elapsedRealtime()

    fun stop(ctx: Context) {
        val prefs = EnginePrefs(ctx)
        prefs.motionUpdatesActive = false
        if (!isAvailable(ctx)) return
        try {
            ActivityRecognition.getClient(ctx)
                .removeActivityTransitionUpdates(pendingIntent(ctx))
            Log.d(TAG, "motion updates removed")
        } catch (e: SecurityException) {
            Log.d(TAG, "motion remove SecurityException")
        }
    }

    private fun pendingIntent(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        REQUEST_CODE,
        Intent(ctx, MotionReceiver::class.java).setAction(ACTION_TRANSITION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
    )
}
