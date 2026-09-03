package com.beratarpa.carkeep

import android.content.Context
import android.util.Log
import org.json.JSONObject

/**
 * Bildirim kurallari (01-spec 7.1). Hesap yapmaz (K-04): Dart'in yazdigi
 * snapshot'taki `dueDay`/`dueKm` degerlerini bugunle ve km ile karsilastirir.
 *
 * Karar veren iki fonksiyon (`evaluateDisconnect`, `evaluateConnect`) **saf**:
 * Android API'si kullanmaz, JVM testlerinden dogrudan cagrilir (denetim md. 22).
 * Yan etkiler `onDisconnected` / `onConnected` icinde.
 */
object ReminderEngine {

    private const val TAG = "CarKeep"

    // `trips.note` degerleri. 02-mimari 3'teki liste yedi deger sayiyor;
    // `no_snapshot` (denetim md. 19) ve `no_permission` (denetim md. 4) K-24
    // ile eklendi. Dart karsiliklari `lib/core/constants.dart`.
    const val NOTE_OK = "ok"
    const val NOTE_SHORT_TRIP = "short_trip"
    const val NOTE_NO_SNAPSHOT = "no_snapshot"
    const val NOTE_SNOOZED = "snoozed"
    const val NOTE_NO_OVERDUE = "no_overdue"
    const val NOTE_ONCE_PER_DAY = "once_per_day"
    const val NOTE_RECONNECT = "reconnect"

    /** Bildirim izni yok: bildirim basilamadi, durum da yazilmadi (denetim md. 4). */
    const val NOTE_NO_PERMISSION = "no_permission"

    /** Motorun karar anindaki durumu; prefs'ten okunur, saf fonksiyona verilir. */
    data class State(
        val connectedAt: Long,
        val lastNotifiedDay: String?,
        val prevLastNotifiedDay: String?,
        val lastNotifiedAt: Long,
        val globalSnoozeUntilDay: String?,
    )

    sealed class Decision {
        data class Notify(val names: List<String>) : Decision()
        data class Skip(val note: String) : Decision()
    }

    sealed class ConnectDecision {
        /** K-06: grace icinde geri baglanma; bildirim geri alinir, surus devam eder. */
        data class Reconnect(val connectedAt: Long) : ConnectDecision()

        /** Yeni surus. */
        data class Start(val connectedAt: Long) : ConnectDecision()

        /** Zaten bagliydi (cift CONNECTED olayi); hicbir sey degismez. */
        object Keep : ConnectDecision()
    }

    /**
     * 01-spec 7.1 `ACL_DISCONNECTED` sirasi, birebir. Saf.
     *
     * Adim 3'un "arac adresi eslesmiyor" yarisi cagiran tarafta: `BtReceiver`
     * zaten adrese gore filtreliyor, `debugSimulate` de [matchesCar] ile ayni
     * kontrolu yapiyor (denetim: kucuk notlar).
     */
    fun evaluateDisconnect(
        snapshot: Snapshot?,
        state: State,
        today: String,
        durationMin: Int,
    ): Decision {
        // 1-2: baglanti bilinmiyorsa duration 0 gelir; kisa surus sayilmaz.
        val minTrip = snapshot?.rules?.minTripMinutes ?: Rules.DEFAULTS.minTripMinutes
        if (durationMin < minTrip) return Decision.Skip(NOTE_SHORT_TRIP)

        // 3: snapshot yok.
        if (snapshot == null) return Decision.Skip(NOTE_NO_SNAPSHOT)

        // 4: genel erteleme ("Yarin").
        state.globalSnoozeUntilDay?.let { if (it > today) return Decision.Skip(NOTE_SNOOZED) }

        // 5-6: gecikmis liste.
        val overdue = snapshot.overdueItems(today)
        if (snapshot.rules.onlyOverdue && overdue.isEmpty()) {
            return Decision.Skip(NOTE_NO_OVERDUE)
        }

        // 7: gunde en fazla bir.
        if (snapshot.rules.oncePerDay && state.lastNotifiedDay == today) {
            return Decision.Skip(NOTE_ONCE_PER_DAY)
        }

        // 8: bildir. `onlyOverdue=false` ve liste bossa isim listesi de bos gider
        // ("Kontroller zamaninda").
        return Decision.Notify(overdue.map { it.name })
    }

    /**
     * 01-spec 7.1 `ACL_CONNECTED`, K-06. Saf.
     *
     * Grace kontrolu `connected_at` kontrolunden **once** yapilir: kopmada
     * `connected_at` sifirlandigi icin tersi olsa dal hic calismazdi
     * (denetim md. 2).
     */
    fun evaluateConnect(
        state: State,
        graceMinutes: Int,
        now: Long,
        previousTripConnectedAt: Long,
    ): ConnectDecision {
        val lastAt = state.lastNotifiedAt
        if (lastAt > 0 && now - lastAt <= graceMinutes * 60_000L) {
            // Surus devam ediyor sayilir: onceki trip'in baslangici korunur.
            return ConnectDecision.Reconnect(
                if (previousTripConnectedAt > 0) previousTripConnectedAt else now,
            )
        }
        if (state.connectedAt >= 0) return ConnectDecision.Keep
        return ConnectDecision.Start(now)
    }

    // ------------------------------------------------------------ yan etkiler

    fun readState(prefs: EnginePrefs): State = State(
        connectedAt = prefs.connectedAt,
        lastNotifiedDay = prefs.lastNotifiedDay,
        prevLastNotifiedDay = prefs.prevLastNotifiedDay,
        lastNotifiedAt = prefs.lastNotifiedAt,
        globalSnoozeUntilDay = prefs.globalSnoozeUntilDay,
    )

    /**
     * 01-spec 7.1: baska cihazlarin olaylari yok sayilir, arac secilmemisse
     * hicbir sey yapilmaz. Saf; JVM testi bunu hedefler.
     */
    fun addressMatches(carAddress: String?, address: String?): Boolean {
        if (carAddress.isNullOrEmpty() || address.isNullOrEmpty()) return false
        return address.equals(carAddress, ignoreCase = true)
    }

    fun matchesCar(prefs: EnginePrefs, address: String?): Boolean =
        addressMatches(prefs.carAddress, address)

    fun onConnected(ctx: Context, prefs: EnginePrefs, now: Long) {
        val snapshot = Snapshot.parse(prefs.snapshotJson)
        val grace = snapshot?.rules?.graceMinutes ?: Rules.DEFAULTS.graceMinutes
        val previousTripConnectedAt = lastTripConnectedAt(prefs)

        when (val decision = evaluateConnect(readState(prefs), grace, now, previousTripConnectedAt)) {
            is ConnectDecision.Reconnect -> {
                Notifications.cancel(ctx)
                prefs.lastNotifiedDay = prefs.prevLastNotifiedDay
                prefs.lastNotifiedAt = -1L
                prefs.updateLastPendingTrip {
                    it.put("counted", false).put("notified", false).put("note", NOTE_RECONNECT)
                }
                prefs.connectedAt = decision.connectedAt
                Log.d(TAG, "reconnect within grace: notification cancelled, trip continues")
            }

            is ConnectDecision.Start -> {
                prefs.connectedAt = decision.connectedAt
                Log.d(TAG, "connected at ${decision.connectedAt}")
            }

            ConnectDecision.Keep ->
                Log.d(TAG, "already connected at ${prefs.connectedAt}, ignoring")
        }
    }

    fun onDisconnected(ctx: Context, prefs: EnginePrefs, now: Long) {
        val connectedAt = prefs.connectedAt
        val durationMin = if (connectedAt > 0) ((now - connectedAt) / 60_000L).toInt() else 0
        prefs.connectedAt = -1L

        val today = DayKey.of(now)
        val snapshot = Snapshot.parse(prefs.snapshotJson)
        val state = readState(prefs).copy(connectedAt = connectedAt)
        val decision = evaluateDisconnect(snapshot, state, today, durationMin)

        val trip = JSONObject()
            .put("type", "trip")
            .put("connectedAt", if (connectedAt > 0) connectedAt else JSONObject.NULL)
            .put("disconnectedAt", now)
            .put("durationMin", durationMin)
            .put("overdueCount", snapshot?.overdueItems(today)?.size ?: 0)

        when (decision) {
            is Decision.Skip -> trip
                .put("counted", decision.note != NOTE_SHORT_TRIP)
                .put("notified", false)
                .put("note", decision.note)

            is Decision.Notify -> {
                Notifications.ensureChannel(ctx)
                val shown = Notifications.showOverdue(ctx, decision.names)
                if (shown) {
                    // Denetim md. 4: durum yalniz bildirim gercekten basildiysa yazilir;
                    // aksi halde izin sonradan verilse de o gun bildirim gelmezdi.
                    prefs.prevLastNotifiedDay = prefs.lastNotifiedDay
                    prefs.lastNotifiedDay = today
                    prefs.lastNotifiedAt = now
                }
                trip
                    .put("counted", true)
                    .put("notified", shown)
                    .put("note", if (shown) NOTE_OK else NOTE_NO_PERMISSION)
            }
        }

        prefs.lastTripJson = trip.toString()
        prefs.appendPendingEvent(trip)
        Log.d(TAG, "disconnect duration=$durationMin decision=$decision")
    }

    private fun lastTripConnectedAt(prefs: EnginePrefs): Long {
        val raw = prefs.lastTripJson ?: return -1L
        return try {
            JSONObject(raw).optLong("connectedAt", -1L)
        } catch (e: Exception) {
            -1L
        }
    }
}
