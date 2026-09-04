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
                    EnginePrefs(ctx).motionUpdatesActive = true
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
