# 07 — Android notları ve Kotlin iskeletleri

Buradaki kodlar iskelettir: yapı ve davranış bağlayıcı, satır satır kopyalanması şart değil. Kural: 01-spec §7 ve 04-kararlar K-03/K-06 ile çelişen hiçbir "iyileştirme" yapılmaz.

## 1. Gradle
`android/app/build.gradle(.kts)`:
- `applicationId = "com.beratarpa.carkeep"`, `minSdk = 26`, `targetSdk`/`compileSdk` = kurulu en yüksek stable.
- Bağımlılıklar (güncel stable sürümler): `androidx.core:core-ktx`, `androidx.work:work-runtime-ktx`, **`com.google.android.gms:play-services-location`** (K-30, hareket doğrulaması; AOSP karşılığı yok). Başka yok.
- Release: `isMinifyEnabled = true` ise `proguard-rules.pro`:
  ```
  -keep class com.beratarpa.carkeep.** { *; }
  ```
  (manifest'te adı geçen receiver/worker sınıfları ve `org.json` kullanımı için yeterli.)
- `kotlinOptions { jvmTarget = "17" }` (Flutter şablonuyla uyumlu olanı koru).

## 2. AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <!-- K-30: API 29+ çalışma zamanı izni; öncesinde gms'in kendi izni. -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <application
        android:label="CarKeep"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Sistem broadcast'i; korumalı action, sahte gönderilemez. exported=true şart. -->
        <receiver android:name=".BtReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.bluetooth.device.action.ACL_CONNECTED" />
                <action android:name="android.bluetooth.device.action.ACL_DISCONNECTED" />
            </intent-filter>
        </receiver>

        <receiver android:name=".NotifActionReceiver" android:exported="false" />

        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
</manifest>
```
Notlar:
- `ACL_CONNECTED/DISCONNECTED` Android 8+ implicit broadcast kısıtından muaftır; manifest receiver uygulama ölüyken çalışır. "Durmaya zorla" sonrası kullanıcı uygulamayı bir kez açana kadar çalışmaz (Android kuralı).
- `BLUETOOTH_CONNECT` (API 31+) runtime izni: hem bonded liste hem de ACL broadcast'inin receiver'a teslimi için gerekir. İzin verilmeden motor çalışmaz; kurulum adım 3 bunu ister.
- WorkManager kendi `BOOT_COMPLETED` receiver'ını taşır; ayrıca eklenmez.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Play Store dışı olduğumuz için doğrudan diyalog kullanılabilir (K-01).

## 3. EnginePrefs.kt ve DayKey.kt
```kotlin
package com.beratarpa.carkeep

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

class EnginePrefs(context: Context) {
    private val sp: SharedPreferences =
        context.applicationContext.getSharedPreferences("carkeep_engine", Context.MODE_PRIVATE)

    private fun str(key: String) = sp.getString(key, null)
    private fun put(key: String, v: String?) { sp.edit().putString(key, v).commit() }   // commit: receiver ölmeden diske
    private fun put(key: String, v: Long) { sp.edit().putLong(key, v).commit() }

    var snapshotJson: String?          get() = str("snapshot_json");            set(v) = put("snapshot_json", v)
    var carAddress: String?            get() = str("car_address");              set(v) = put("car_address", v)
    var connectedAt: Long              get() = sp.getLong("connected_at", -1L); set(v) = put("connected_at", v)
    var lastNotifiedDay: String?       get() = str("last_notified_day");        set(v) = put("last_notified_day", v)
    var prevLastNotifiedDay: String?   get() = str("prev_last_notified_day");   set(v) = put("prev_last_notified_day", v)
    var lastNotifiedAt: Long           get() = sp.getLong("last_notified_at", -1L); set(v) = put("last_notified_at", v)
    var globalSnoozeUntilDay: String?  get() = str("global_snooze_until_day"); set(v) = put("global_snooze_until_day", v)
    var lastTripJson: String?          get() = str("last_trip_json");           set(v) = put("last_trip_json", v)

    fun appendPendingEvent(obj: JSONObject) {
        val arr = JSONArray(sp.getString("pending_events_json", "[]"))
        arr.put(obj)
        put("pending_events_json", arr.toString())
    }

    /** Son trip olayını yerinde günceller (hızlı geri bağlanma için). */
    fun updateLastPendingTrip(mutate: (JSONObject) -> Unit) {
        val arr = JSONArray(sp.getString("pending_events_json", "[]"))
        for (i in arr.length() - 1 downTo 0) {
            val o = arr.getJSONObject(i)
            if (o.optString("type") == "trip") { mutate(o); break }
        }
        put("pending_events_json", arr.toString())
        lastTripJson?.let { JSONObject(it).also(mutate).let { j -> lastTripJson = j.toString() } }
    }

    fun drainPendingEvents(): String {
        val s = sp.getString("pending_events_json", "[]") ?: "[]"
        put("pending_events_json", "[]")
        return s
    }

    fun clearAll() { sp.edit().clear().commit() }
}
```
```kotlin
package com.beratarpa.carkeep

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** Yerel saat dilimi, yyyy-MM-dd. String karşılaştırması kronolojik sıralamaya eşittir. */
object DayKey {
    private fun fmt() = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    fun of(millis: Long): String = fmt().format(Date(millis))
    fun today(): String = of(System.currentTimeMillis())
    fun plusDays(day: String, n: Int): String {
        val c = Calendar.getInstance(); c.time = fmt().parse(day)!!; c.add(Calendar.DAY_OF_MONTH, n); return fmt().format(c.time)
    }
    /** b - a takvim günü. */
    fun daysBetween(a: String, b: String): Int {
        val ca = Calendar.getInstance().apply { time = fmt().parse(a)!! }
        val cb = Calendar.getInstance().apply { time = fmt().parse(b)!! }
        return ((cb.timeInMillis - ca.timeInMillis + 12 * 3600_000L) / 86_400_000L).toInt()  // DST toleransı
    }
}
```

## 4. Snapshot.kt, ReminderEngine.kt, BtReceiver.kt
```kotlin
package com.beratarpa.carkeep

import org.json.JSONObject

data class SnapshotItem(val id: Long, val name: String, val dueDay: String?, val dueKm: Long?, val snoozeUntilDay: String?) {
    fun isOverdue(today: String, km: Long) = (dueDay != null && dueDay < today) || (dueKm != null && dueKm < km)
    fun isSnoozed(today: String) = snoozeUntilDay != null && snoozeUntilDay > today
}
data class Rules(val onlyOverdue: Boolean, val oncePerDay: Boolean, val minTripMinutes: Int, val graceMinutes: Int, val fallbackAfterDays: Int)
data class Snapshot(val carAddress: String?, val carName: String?, val km: Long, val rules: Rules, val items: List<SnapshotItem>) {
    fun overdueItems(today: String) = items.filter { it.isOverdue(today, km) && !it.isSnoozed(today) }
    companion object {
        fun parse(json: String?): Snapshot? = try {
            if (json == null) null else JSONObject(json).let { o ->
                val car = o.getJSONObject("car"); val r = o.getJSONObject("rules"); val arr = o.getJSONArray("items")
                Snapshot(
                    carAddress = car.optString("address").ifEmpty { null },
                    carName = car.optString("name").ifEmpty { null },
                    km = car.getLong("km"),
                    rules = Rules(r.getBoolean("onlyOverdue"), r.getBoolean("oncePerDay"), r.getInt("minTripMinutes"), r.getInt("graceMinutes"), r.getInt("fallbackAfterDays")),
                    items = (0 until arr.length()).map { i -> arr.getJSONObject(i).let { it2 ->
                        SnapshotItem(it2.getLong("id"), it2.getString("name"),
                            it2.optString("dueDay").ifEmpty { null },
                            if (it2.isNull("dueKm")) null else it2.getLong("dueKm"),
                            it2.optString("snoozeUntilDay").ifEmpty { null }) } }
                )
            }
        } catch (e: Exception) { null }
    }
}
```
```kotlin
package com.beratarpa.carkeep

import android.content.Context
import android.util.Log
import org.json.JSONObject

object ReminderEngine {
    private const val TAG = "CarKeep"

    data class State(val connectedAt: Long, val lastNotifiedDay: String?, val lastNotifiedAt: Long, val globalSnoozeUntilDay: String?)

    sealed class Decision {
        data class Notify(val names: List<String>) : Decision()
        data class Skip(val note: String) : Decision()
    }

    /** Saf fonksiyon; JVM testleri bunu hedefler. 01-spec §7.1 sırası. */
    fun evaluateDisconnect(snapshot: Snapshot?, state: State, today: String, durationMin: Int): Decision {
        val minTrip = snapshot?.rules?.minTripMinutes ?: 5
        if (durationMin < minTrip) return Decision.Skip("short_trip")
        if (snapshot == null) return Decision.Skip("no_snapshot")
        state.globalSnoozeUntilDay?.let { if (it > today) return Decision.Skip("snoozed") }
        val overdue = snapshot.overdueItems(today)
        if (snapshot.rules.onlyOverdue && overdue.isEmpty()) return Decision.Skip("no_overdue")
        if (snapshot.rules.oncePerDay && state.lastNotifiedDay == today) return Decision.Skip("once_per_day")
        return Decision.Notify(overdue.map { it.name })
    }

    fun onConnected(ctx: Context, prefs: EnginePrefs, now: Long) {
        val snapshot = Snapshot.parse(prefs.snapshotJson)
        val graceMs = (snapshot?.rules?.graceMinutes ?: 2) * 60_000L
        val lastAt = prefs.lastNotifiedAt
        if (lastAt > 0 && now - lastAt <= graceMs) {
            // K-06: hızlı geri bağlanma → bildirimi geri al, sürüş devam ediyor say
            Notifications.cancel(ctx)
            prefs.lastNotifiedDay = prefs.prevLastNotifiedDay
            prefs.lastNotifiedAt = -1
            val prevConnectedAt = prefs.lastTripJson?.let { JSONObject(it).optLong("connectedAt", -1L) } ?: -1L
            prefs.updateLastPendingTrip { it.put("counted", false).put("notified", false).put("note", "reconnect") }
            prefs.connectedAt = if (prevConnectedAt > 0) prevConnectedAt else now
            Log.d(TAG, "reconnect within grace: notification cancelled, trip continues")
            return
        }
        if (prefs.connectedAt < 0) prefs.connectedAt = now   // çift CONNECTED olayında ilk değer korunur
        Log.d(TAG, "connected at ${prefs.connectedAt}")
    }

    fun onDisconnected(ctx: Context, prefs: EnginePrefs, now: Long) {
        val connectedAt = prefs.connectedAt
        val durationMin = if (connectedAt > 0) ((now - connectedAt) / 60_000L).toInt() else 0
        prefs.connectedAt = -1
        val today = DayKey.of(now)
        val snapshot = Snapshot.parse(prefs.snapshotJson)
        val state = State(connectedAt, prefs.lastNotifiedDay, prefs.lastNotifiedAt, prefs.globalSnoozeUntilDay)
        val decision = evaluateDisconnect(snapshot, state, today, durationMin)

        val trip = JSONObject().put("type", "trip")
            .put("connectedAt", if (connectedAt > 0) connectedAt else JSONObject.NULL)
            .put("disconnectedAt", now).put("durationMin", durationMin)
            .put("overdueCount", snapshot?.overdueItems(today)?.size ?: 0)
        when (decision) {
            is Decision.Skip -> trip.put("counted", decision.note != "short_trip").put("notified", false).put("note", decision.note)
            is Decision.Notify -> {
                Notifications.ensureChannel(ctx)
                Notifications.showOverdue(ctx, decision.names)
                prefs.prevLastNotifiedDay = prefs.lastNotifiedDay
                prefs.lastNotifiedDay = today
                prefs.lastNotifiedAt = now
                trip.put("counted", true).put("notified", true).put("note", "ok")
            }
        }
        prefs.lastTripJson = trip.toString()
        prefs.appendPendingEvent(trip)
        Log.d(TAG, "disconnect duration=$durationMin decision=$decision")
    }
}
```
```kotlin
package com.beratarpa.carkeep

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BtReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33)
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        else @Suppress("DEPRECATION") intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        val address = device?.address ?: return          // address okumak izin istemez; name ister, kullanma
        val prefs = EnginePrefs(context)
        if (!address.equals(prefs.carAddress, ignoreCase = true)) return
        val now = System.currentTimeMillis()
        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> ReminderEngine.onConnected(context, prefs, now)
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> ReminderEngine.onDisconnected(context, prefs, now)
        }
    }
}
```

## 5. Notifications.kt, NotifActionReceiver.kt, DailyCheckWorker.kt
```kotlin
package com.beratarpa.carkeep

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object Notifications {
    const val CHANNEL_ID = "reminders"
    const val NOTIF_ID = 1001
    const val EXTRA_ACTION = "carkeep_action"
    const val ACTION_SNOOZE = "com.beratarpa.carkeep.SNOOZE"

    fun ensureChannel(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(NotificationChannel(CHANNEL_ID, "CarKeep hatırlatmaları", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Arabadan inince gecikmiş kontroller"
            enableVibration(true)
        })
    }

    /** names boş olabilir (onlyOverdue=false modu). daysNoDrive yalnız yedek bildirimde. */
    fun showOverdue(ctx: Context, names: List<String>, daysNoDrive: Int? = null) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val title = if (names.isEmpty()) "Kontroller zamanında" else "${names.size} kontrol gecikti"
        val prefix = when { daysNoDrive == null -> ""; daysNoDrive > 0 -> "$daysNoDrive gündür sürüş yok. "; else -> "Bir süredir sürüş yok. " }
        val short = when {
            names.isEmpty() -> "Gecikmiş bir şey yok."
            names.size <= 3 -> names.joinToString(", ")
            else -> names.take(3).joinToString(", ") + " ve ${names.size - 3} daha"
        }
        val big = prefix + names.joinToString("\n") + if (names.isEmpty()) "" else "\nArabanın yanındayken birkaç dakika sürer."
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val openPi = PendingIntent.getActivity(ctx, 1, Intent(ctx, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP); putExtra(EXTRA_ACTION, "overdue") }, flags)
        val snoozePi = PendingIntent.getBroadcast(ctx, 2, Intent(ctx, NotifActionReceiver::class.java).apply { action = ACTION_SNOOZE }, flags)
        val n = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_carkeep)          // tek renk vektör, T12'de eklenir
            .setContentTitle(title).setContentText(prefix + short)
            .setStyle(NotificationCompat.BigTextStyle().bigText(big))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true).setOnlyAlertOnce(true)
            .setContentIntent(openPi)
            .addAction(0, "Aç", openPi)
            .addAction(0, "Yarın", snoozePi)
            .build()
        NotificationManagerCompat.from(ctx).notify(NOTIF_ID, n)
    }

    fun cancel(ctx: Context) = NotificationManagerCompat.from(ctx).cancel(NOTIF_ID)
}
```
```kotlin
package com.beratarpa.carkeep

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

class NotifActionReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Notifications.ACTION_SNOOZE) return
        val prefs = EnginePrefs(ctx)
        val until = DayKey.plusDays(DayKey.today(), 1)
        prefs.globalSnoozeUntilDay = until
        Notifications.cancel(ctx)
        prefs.appendPendingEvent(JSONObject().put("type", "snooze").put("untilDay", until))
    }
}
```
```kotlin
package com.beratarpa.carkeep

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

class DailyCheckWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {
    override fun doWork(): Result {
        runOnce(applicationContext)
        schedule(applicationContext)             // kendini yeniden planla
        return Result.success()
    }

    companion object {
        const val UNIQUE = "daily_check"
        const val TARGET_HOUR = 19

        /** 01-spec §7.2. debugRunDailyWorker da bunu çağırır. */
        fun runOnce(ctx: Context) {
            val prefs = EnginePrefs(ctx)
            val snapshot = Snapshot.parse(prefs.snapshotJson) ?: return
            val rules = snapshot.rules
            if (rules.fallbackAfterDays <= 0) return
            val today = DayKey.today()
            prefs.globalSnoozeUntilDay?.let { if (it > today) return }
            val overdue = snapshot.overdueItems(today)
                .filter { it.dueDay != null && DayKey.daysBetween(it.dueDay, today) >= rules.fallbackAfterDays }
            if (overdue.isEmpty()) return
            prefs.lastNotifiedDay?.let { if (DayKey.daysBetween(it, today) < 3) return }
            val daysNoDrive = prefs.lastTripJson?.let { JSONObject(it).optLong("disconnectedAt", -1L) }
                ?.takeIf { it > 0 }?.let { DayKey.daysBetween(DayKey.of(it), today) } ?: -1
            Notifications.ensureChannel(ctx)
            Notifications.showOverdue(ctx, overdue.map { it.name }, daysNoDrive = daysNoDrive)
            prefs.prevLastNotifiedDay = prefs.lastNotifiedDay
            prefs.lastNotifiedDay = today
            prefs.lastNotifiedAt = System.currentTimeMillis()
            prefs.appendPendingEvent(JSONObject().put("type", "fallback").put("at", System.currentTimeMillis()).put("overdueCount", overdue.size))
        }

        fun schedule(ctx: Context) {
            val now = Calendar.getInstance()
            val target = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, TARGET_HOUR); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                if (!after(now)) add(Calendar.DAY_OF_MONTH, 1)
            }
            val req = OneTimeWorkRequestBuilder<DailyCheckWorker>()
                .setInitialDelay(target.timeInMillis - now.timeInMillis, TimeUnit.MILLISECONDS).build()
            WorkManager.getInstance(ctx).enqueueUniqueWork(UNIQUE, ExistingWorkPolicy.REPLACE, req)
        }
    }
}
```

## 6. MainActivity.kt (kanal)
```kotlin
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
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.beratarpa.carkeep/platform")
        channel!!.setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun hasBt() = Build.VERSION.SDK_INT < 31 ||
        checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
    private fun hasNotif() = Build.VERSION.SDK_INT < 33 ||
        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val prefs = EnginePrefs(this)
        when (call.method) {
            "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
            "hasBluetoothPermission" -> result.success(hasBt())
            "requestBluetoothPermission" -> if (hasBt()) result.success(true) else {
                pendingPermission = result
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.BLUETOOTH_CONNECT), REQ_PERM)
            }
            "hasNotificationPermission" -> result.success(hasNotif())
            "requestNotificationPermission" -> if (hasNotif()) result.success(true) else {
                pendingPermission = result
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_PERM)
            }
            "getBondedDevices" -> {
                if (!hasBt()) { result.error("NO_PERMISSION", "BLUETOOTH_CONNECT", null); return }
                val adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
                result.success(adapter?.bondedDevices?.map { mapOf("name" to (it.name ?: ""), "address" to it.address) } ?: emptyList<Map<String, String>>())
            }
            "isIgnoringBatteryOptimizations" ->
                result.success((getSystemService(Context.POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName))
            "openBatteryOptimizationSettings" -> {
                try { startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))) }
                catch (e: Exception) { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) }
                result.success(null)
            }
            "openAppSettings" -> { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))); result.success(null) }
            "writeSnapshot" -> {
                val json = call.argument<String>("json")!!
                prefs.snapshotJson = json
                prefs.carAddress = Snapshot.parse(json)?.carAddress
                result.success(null)
            }
            "readSnapshot" -> result.success(prefs.snapshotJson)
            "drainPendingEvents" -> result.success(prefs.drainPendingEvents())
            "getBluetoothState" -> result.success(mapOf(
                "connected" to (prefs.connectedAt > 0),
                "since" to prefs.connectedAt.takeIf { it > 0 },
                "lastTrip" to prefs.lastTripJson))
            "getLaunchAction" -> {
                val a = intent?.getStringExtra(Notifications.EXTRA_ACTION)
                intent?.removeExtra(Notifications.EXTRA_ACTION)
                result.success(a)
            }
            "scheduleDailyWorker" -> { DailyCheckWorker.schedule(this); result.success(null) }
            "clearEngine" -> { prefs.clearAll(); Notifications.cancel(this); result.success(null) }   // Verileri sıfırla
            "debugSimulate" -> if (!BuildConfig.DEBUG) result.error("NOT_DEBUG", null, null) else {
                val minutes = call.argument<Int>("minutes") ?: 25
                val now = System.currentTimeMillis()
                when (call.argument<String>("event")) {
                    "connect" -> ReminderEngine.onConnected(this, prefs, now)
                    "disconnect" -> { prefs.connectedAt = now - minutes * 60_000L; ReminderEngine.onDisconnected(this, prefs, now) }
                }
                result.success(null)
            }
            "debugRunDailyWorker" -> if (!BuildConfig.DEBUG) result.error("NOT_DEBUG", null, null) else { DailyCheckWorker.runOnce(this); result.success(null) }
            else -> result.notImplemented()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(Notifications.EXTRA_ACTION)?.let { channel?.invokeMethod("onLaunchAction", it) }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_PERM) {
            pendingPermission?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            pendingPermission = null
        }
    }

    companion object { const val REQ_PERM = 1001 }
}
```
Notlar:
- `clearEngine` 02-mimari §6 tablosuna ek metottur (Verileri sıfırla).
- `launch_action` prefs anahtarı v1'de kullanılmaz; intent extra yeterli.
- `debugSimulate` receiver'ın adres filtresini atlar; `car_address` boş olsa da motoru çalıştırır (snapshot yoksa `no_snapshot` döner).

## 7. OEM pil kısıtları (Ayarlar → Uygulama metinleri `Build.MANUFACTURER`'a göre)
| Üretici | Yapılacak |
|---|---|
| Xiaomi / Redmi / POCO (MIUI, HyperOS) | Uygulama bilgisi → "Otomatik başlatma" açık; Pil tasarrufu → "Kısıtlama yok". Güvenlik uygulaması → Uygulamaları hızlandır → kilit. |
| Samsung (One UI) | Pil → "Kısıtlanmamış"; Pil → Arka plan kullanım sınırları → "Uyku moduna alınmayacak uygulamalar"a ekle; "Kullanılmayan uygulamaları uyku moduna al" kapalı. |
| Huawei / Honor | Pil → Uygulama başlatma → Elle yönet: Otomatik başlat, İkincil başlat, Arka planda çalış açık. |
| Oppo / Realme / OnePlus (ColorOS) | Pil → "Arka planda çalışmaya izin ver"; Otomatik başlatma açık; "Akıllı güç tasarrufu" kapalı. |
| Google Pixel / stok Android | Pil optimizasyonu diyaloğu yeterli. |
Referans: dontkillmyapp.com (metinlere bağlantı olarak eklenebilir). T17'de gerçek cihazın markasına göre doğrulanır.

## 8. Doze, App Standby, Force stop
- Doze'da broadcast teslimi sürer; receiver kısa çalıştığı için etkilenmez. `adb shell dumpsys deviceidle force-idle` ile test (06 §4).
- App Standby "restricted" kovasında bazı OEM'ler receiver'ı geciktirir; pil ayarı "Kısıtlanmamış" olmalı. Uygulama içi uyarı şeridi bunu söyler.
- "Durmaya zorla" sonrası tüm manifest receiver'lar kullanıcı uygulamayı açana kadar devre dışı (Android tasarımı). Ayarlar → Uygulama'da açıklama: "Uygulamayı durmaya zorlarsan hatırlatma durur; bir kez açman yeter."
- Bildirim kanalı kullanıcı tarafından kapatılırsa `NotificationManagerCompat.areNotificationsEnabled()` / kanal önemi kontrolü ile uyarı şeridi (T16).

## 9. Bilinen tuzaklar
- `BluetoothDevice.name` okumak API 31+'da `BLUETOOTH_CONNECT` ister; receiver'da yalnız `address` kullan.
- Aynı cihaz için birden fazla `ACL_CONNECTED` gelebilir (profil yeniden bağlanması); `connectedAt` korunur.
- Bazı head unit'ler kontak kapanınca 10–20 sn sonra kopar; "≤ 30 sn" ölçütü bunu içerir.
- `PendingIntent` `FLAG_IMMUTABLE` zorunlu (API 31+).
- `SharedPreferences.commit()` receiver'da kasıtlı; `apply()` süreç ölürse kaybolabilir.
- Kotlin JVM testleri Android sınıfı kullanmasın: `ReminderEngine.evaluateDisconnect` ve `Snapshot.parse` (`org.json` için `testImplementation("org.json:json:…")`) saf kalsın.
