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

            // 01-spec 9: kalici ret. Android'de dogrudan API yok; konvansiyon
            // "izin yok + gerekce gosterilmeyecek". "Daha once soruldu mu"
            // bilgisini Dart tutuyor (ilk acilista da false doner).
            "shouldShowPermissionRationale" -> {
                val which = call.argument<String>("permission")
                val permission = when (which) {
                    "bluetooth" -> Manifest.permission.BLUETOOTH_CONNECT
                    "notification" -> Manifest.permission.POST_NOTIFICATIONS
                    "motion" -> MotionTracker.PERMISSION
                    else -> null
                }
                if (permission == null) {
                    result.error("BAD_ARGS", "permission: bluetooth|notification|motion", null)
                    return
                }
                result.success(
                    ActivityCompat.shouldShowRequestPermissionRationale(this, permission),
                )
            }

            "areNotificationsEnabled" ->
                result.success(Notifications.areNotificationsEnabled(this))

            // K-30 -------------------------------------------------- hareket
            "isMotionAvailable" -> result.success(MotionTracker.isAvailable(this))

            "hasMotionPermission" -> result.success(MotionTracker.hasPermission(this))

            "requestMotionPermission" ->
                if (MotionTracker.hasPermission(this)) {
                    result.success(true)
                } else {
                    requestPermission(MotionTracker.PERMISSION, result)
                }

            /**
             * Aboneligi acar/kapatir. Donen deger "abonelik gercekten kuruldu
             * mu"; Dart kurali yalniz true donunce aciyor.
             */
            "setMotionUpdates" -> {
                val on = call.argument<Boolean>("enabled") == true
                if (on) {
                    result.success(MotionTracker.start(this))
                } else {
                    MotionTracker.stop(this)
                    result.success(false)
                }
            }

            "isMotionActive" -> result.success(prefs.motionUpdatesActive)

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

            // 02-mimari 6: yalniz debug derlemede. Receiver'i atladigi icin
            // arac adresi kontrolunu burada kendisi yapar (01-spec 7.1 adim 3).
            "debugSimulate" -> {
                if (!BuildConfig.DEBUG) {
                    result.error("NOT_DEBUG", "Yalniz debug derlemede", null)
                    return
                }
                val event = call.argument<String>("event")
                val minutes = call.argument<Int>("minutes") ?: 0
                val address = prefs.carAddress
                if (address == null || !ReminderEngine.matchesCar(prefs, address)) {
                    result.error("NO_CAR", "Arac Bluetooth cihazi secilmedi", null)
                    return
                }
                val now = System.currentTimeMillis()
                when (event) {
                    "connect" -> ReminderEngine.onConnected(this, prefs, now)
                    "disconnect" -> {
                        if (minutes > 0) {
                            prefs.connectedAt = now - minutes * 60_000L
                        }
                        ReminderEngine.onDisconnected(this, prefs, now)
                    }
                    // K-30: `IN_VEHICLE` gecisi taklidi; hareket kuralini
                    // cihazda arabaya binmeden denemek icin.
                    "motion" -> prefs.lastInVehicleAt = now
                    else -> {
                        result.error("BAD_ARGS", "event: connect|disconnect|motion", null)
                        return
                    }
                }
                Log.d(TAG, "debugSimulate $event ${minutes}dk")
                result.success(null)
            }

            // T14: yedek isi elle calistir (02-mimari 6, yalniz debug).
            "debugRunDailyWorker" -> {
                if (!BuildConfig.DEBUG) {
                    result.error("NOT_DEBUG", "Yalniz debug derlemede", null)
                    return
                }
                DailyCheckWorker.runOnce(this)
                result.success(null)
            }

            // 01-spec 9: DB acilamazsa tam ekran hatadaki "Verileri sifirla".
            // Drift dosyasi Flutter'in belge dizininde; kanal Dart'tan once
            // hazir oldugu icin acilisin en basinda cagrilabilir.
            "deleteDatabase" -> {
                val deleted = deleteDatabaseFiles()
                prefs.clearAll()
                Notifications.cancel(this)
                Log.d(TAG, "database files deleted: $deleted")
                result.success(deleted)
            }

            "clearEngine" -> {
                // K-30: abonelik prefs disinda; bayrakla birlikte o da gitmeli.
                MotionTracker.stop(this)
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

    /** `carkeep.sqlite*` dosyalarini uygulama veri dizininde arar ve siler. */
    private fun deleteDatabaseFiles(): Int {
        val root = applicationInfo.dataDir?.let { java.io.File(it) } ?: return 0
        var count = 0
        root.walkTopDown().forEach { file ->
            if (file.isFile && file.name.startsWith("carkeep.sqlite")) {
                if (file.delete()) count++
            }
        }
        return count
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
        val action = intent.getStringExtra(Notifications.EXTRA_ACTION) ?: return
        val target = channel
        if (target == null) {
            // Dart heniz bagli degil; extra'yi birak, `getLaunchAction` alsin.
            return
        }
        // Tuketiliyor: aksi halde ardindan gelen `resume` ayni eylemi
        // `getLaunchAction` ile ikinci kez okur.
        intent.removeExtra(Notifications.EXTRA_ACTION)
        target.invokeMethod("onLaunchAction", action)
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
