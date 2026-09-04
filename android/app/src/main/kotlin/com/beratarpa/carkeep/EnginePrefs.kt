package com.beratarpa.carkeep

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Dart ile Kotlin arasindaki tek ortak veri (02-mimari 7).
 * Tum yazimlar `commit()`: receiver surec olmeden diske insin.
 */
class EnginePrefs(context: Context) {

    private val sp: SharedPreferences =
        context.applicationContext.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    private fun str(key: String) = sp.getString(key, null)

    private fun put(key: String, v: String?) {
        sp.edit().putString(key, v).commit()
    }

    private fun putLong(key: String, v: Long) {
        sp.edit().putLong(key, v).commit()
    }

    var snapshotJson: String?
        get() = str(KEY_SNAPSHOT)
        set(v) = put(KEY_SNAPSHOT, v)

    var carAddress: String?
        get() = str(KEY_CAR_ADDRESS)
        set(v) = put(KEY_CAR_ADDRESS, v)

    var connectedAt: Long
        get() = sp.getLong(KEY_CONNECTED_AT, -1L)
        set(v) = putLong(KEY_CONNECTED_AT, v)

    var lastNotifiedDay: String?
        get() = str(KEY_LAST_NOTIFIED_DAY)
        set(v) = put(KEY_LAST_NOTIFIED_DAY, v)

    var prevLastNotifiedDay: String?
        get() = str(KEY_PREV_LAST_NOTIFIED_DAY)
        set(v) = put(KEY_PREV_LAST_NOTIFIED_DAY, v)

    var lastNotifiedAt: Long
        get() = sp.getLong(KEY_LAST_NOTIFIED_AT, -1L)
        set(v) = putLong(KEY_LAST_NOTIFIED_AT, v)

    var globalSnoozeUntilDay: String?
        get() = str(KEY_GLOBAL_SNOOZE)
        set(v) = put(KEY_GLOBAL_SNOOZE, v)

    var lastTripJson: String?
        get() = str(KEY_LAST_TRIP)
        set(v) = put(KEY_LAST_TRIP, v)

    /** K-30: son `IN_VEHICLE` gecisinin zamani; hic gorulmediyse -1. */
    var lastInVehicleAt: Long
        get() = sp.getLong(KEY_LAST_IN_VEHICLE_AT, -1L)
        set(v) = putLong(KEY_LAST_IN_VEHICLE_AT, v)

    /** K-34: aboneligin kuruldugu acilisin damgasi (boot wall-clock). */
    var motionRegisteredBootAt: Long
        get() = sp.getLong(KEY_MOTION_BOOT_AT, -1L)
        set(v) = putLong(KEY_MOTION_BOOT_AT, v)

    /**
     * K-30: gecis aboneligi gercekten kurulu mu. Kural acik ama abonelik yoksa
     * motor hareket kontrolunu **atlar**; aksi halde bildirim hic gelmezdi.
     */
    var motionUpdatesActive: Boolean
        get() = sp.getBoolean(KEY_MOTION_ACTIVE, false)
        set(v) {
            sp.edit().putBoolean(KEY_MOTION_ACTIVE, v).commit()
        }

    fun appendPendingEvent(obj: JSONObject) {
        val arr = readPendingEvents()
        arr.put(obj)
        put(KEY_PENDING_EVENTS, arr.toString())
    }

    /** Son trip olayini yerinde gunceller (hizli geri baglanma, K-06). */
    fun updateLastPendingTrip(mutate: (JSONObject) -> Unit) {
        val arr = readPendingEvents()
        for (i in arr.length() - 1 downTo 0) {
            val o = arr.optJSONObject(i) ?: continue
            if (o.optString("type") == "trip") {
                mutate(o)
                break
            }
        }
        put(KEY_PENDING_EVENTS, arr.toString())
        lastTripJson?.let { raw ->
            val j = try {
                JSONObject(raw)
            } catch (e: Exception) {
                null
            }
            if (j != null) {
                mutate(j)
                lastTripJson = j.toString()
            }
        }
    }

    /** Oku + sil, tek cagri (01-spec 7.3). */
    fun drainPendingEvents(): String {
        val s = sp.getString(KEY_PENDING_EVENTS, EMPTY_ARRAY) ?: EMPTY_ARRAY
        put(KEY_PENDING_EVENTS, EMPTY_ARRAY)
        return s
    }

    fun clearAll() {
        sp.edit().clear().commit()
    }

    private fun readPendingEvents(): JSONArray {
        val raw = sp.getString(KEY_PENDING_EVENTS, EMPTY_ARRAY) ?: EMPTY_ARRAY
        return try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
    }

    companion object {
        const val NAME = "carkeep_engine"
        const val EMPTY_ARRAY = "[]"

        const val KEY_SNAPSHOT = "snapshot_json"
        const val KEY_CAR_ADDRESS = "car_address"
        const val KEY_CONNECTED_AT = "connected_at"
        const val KEY_LAST_NOTIFIED_DAY = "last_notified_day"
        const val KEY_PREV_LAST_NOTIFIED_DAY = "prev_last_notified_day"
        const val KEY_LAST_NOTIFIED_AT = "last_notified_at"
        const val KEY_GLOBAL_SNOOZE = "global_snooze_until_day"
        const val KEY_PENDING_EVENTS = "pending_events_json"
        const val KEY_LAST_TRIP = "last_trip_json"
        const val KEY_LAST_IN_VEHICLE_AT = "last_in_vehicle_at"
        const val KEY_MOTION_ACTIVE = "motion_updates_active"
        const val KEY_MOTION_BOOT_AT = "motion_registered_boot_at"
    }
}
