package com.beratarpa.carkeep

import android.Manifest
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Tek `MethodChannel` (K-05). Metot listesi 02-mimari 6.
 * `debug*` metotlari T12'de eklenir.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result -> handle(call, result) }
        }
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        pendingPermission = null
        super.onDestroy()
    }

    private fun hasBt(): Boolean =
        Build.VERSION.SDK_INT < 31 ||
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasNotif(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val prefs = EnginePrefs(this)
        when (call.method) {
            "getSdkInt" -> result.success(Build.VERSION.SDK_INT)

            "getManufacturer" -> result.success(Build.MANUFACTURER ?: "")

            "hasBluetoothPermission" -> result.success(hasBt())

            "requestBluetoothPermission" ->
                if (hasBt()) {
                    result.success(true)
                } else {
                    requestPermission(Manifest.permission.BLUETOOTH_CONNECT, result)
                }

            "hasNotificationPermission" -> result.success(hasNotif())

            "requestNotificationPermission" ->
                if (hasNotif()) {
                    result.success(true)
                } else {
                    requestPermission(Manifest.permission.POST_NOTIFICATIONS, result)
                }

            "areNotificationsEnabled" ->
                result.success(Notifications.areNotificationsEnabled(this))

            // Adaptor kapaliyken `getBondedDevices` bos liste doner; cihaz
            // secici "eslesmis cihaz yok" yerine "Bluetooth kapali" demeli.
            "isBluetoothEnabled" -> {
                val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                result.success(manager?.adapter?.isEnabled == true)
            }

            "getBondedDevices" -> {
                if (!hasBt()) {
                    result.error("NO_PERMISSION", "BLUETOOTH_CONNECT", null)
                    return
                }
                val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = manager?.adapter
                if (adapter == null) {
                    result.error("NO_ADAPTER", "Bluetooth adaptoru yok", null)
                    return
                }
                val devices = try {
                    adapter.bondedDevices.orEmpty().map {
                        mapOf("name" to (it.name ?: ""), "address" to it.address)
                    }
                } catch (e: SecurityException) {
                    result.error("NO_PERMISSION", "BLUETOOTH_CONNECT", null)
                    return
                }
                result.success(devices)
            }

            "isIgnoringBatteryOptimizations" -> {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(pm.isIgnoringBatteryOptimizations(packageName))
            }

            "openBatteryOptimizationSettings" -> {
                // 07 6: Play Store disi oldugumuz icin dogrudan diyalog (K-01).
                val opened = tryStart(
                    Intent(
                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        Uri.parse("package:$packageName"),
                    )
                ) || tryStart(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) ||
                    tryStart(appDetailsIntent())
                Log.d(TAG, "battery settings opened=$opened")
                result.success(null)
            }

            "openAppSettings" -> {
                tryStart(appDetailsIntent())
                result.success(null)
            }

            "openNotificationSettings" -> {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                if (!tryStart(intent)) tryStart(appDetailsIntent())
                result.success(null)
            }

            "writeSnapshot" -> {
                val json = call.argument<String>("json")
                if (json == null) {
                    result.error("BAD_ARGS", "json zorunlu", null)
                    return
                }
                prefs.snapshotJson = json
                prefs.carAddress = Snapshot.parseCarAddress(json)
                result.success(null)
            }

            "readSnapshot" -> result.success(prefs.snapshotJson)

            "drainPendingEvents" -> result.success(prefs.drainPendingEvents())

            "getBluetoothState" -> result.success(
                mapOf(
                    "connected" to (prefs.connectedAt > 0),
                    "since" to prefs.connectedAt.takeIf { it > 0 },
                    "lastTrip" to prefs.lastTripJson,
                )
            )

            "getLaunchAction" -> {
                val action = intent?.getStringExtra(Notifications.EXTRA_ACTION)
                intent?.removeExtra(Notifications.EXTRA_ACTION)
                result.success(action)
            }

            "scheduleDailyWorker" -> {
                DailyCheckWorker.schedule(this)
                result.success(null)
            }

            "cancelNotification" -> {
                Notifications.cancel(this)
                result.success(null)
            }

            "clearEngine" -> {
                prefs.clearAll()
                Notifications.cancel(this)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun requestPermission(permission: String, result: MethodChannel.Result) {
        val previous = pendingPermission
        pendingPermission = result
        // Ust uste istek gelirse onceki cagriyi bosta birakma.
        previous?.success(false)
        ActivityCompat.requestPermissions(this, arrayOf(permission), REQ_PERM)
    }

    private fun appDetailsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))

    private fun tryStart(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (e: Exception) {
        Log.d(TAG, "startActivity failed: ${intent.action}")
        false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(Notifications.EXTRA_ACTION)?.let {
            channel?.invokeMethod("onLaunchAction", it)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ_PERM) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    companion object {
        const val CHANNEL = "com.beratarpa.carkeep/platform"
        const val REQ_PERM = 1001
        private const val TAG = "CarKeep"
    }
}
