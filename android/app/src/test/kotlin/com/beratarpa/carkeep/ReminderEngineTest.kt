package com.beratarpa.carkeep

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

/**
 * 06-test-plani 2 tablosu. Her satir bir test.
 *
 * Snapshot: A `dueDay 2026-09-01` (gecikmis), B `dueKm 118000` (gecikmis, km
 * 118420), C `dueDay 2026-09-10`.
 */
class ReminderEngineTest {

    private val today = "2026-09-03"
    private val car = "12:34:56:78:9A:BC"

    private fun item(
        id: Long,
        name: String,
        dueDay: String? = null,
        dueKm: Long? = null,
        snoozeUntilDay: String? = null,
    ) = SnapshotItem(id, name, dueDay, dueKm, snoozeUntilDay)

    private fun snapshot(
        onlyOverdue: Boolean = true,
        oncePerDay: Boolean = true,
        minTripMinutes: Int = 5,
        graceMinutes: Int = 2,
        fallbackAfterDays: Int = 7,
        items: List<SnapshotItem> = defaultItems(),
        km: Long = 118_420,
    ) = Snapshot(
        version = 1,
        carAddress = car,
        carName = "Uconnect",
        km = km,
        rules = Rules(onlyOverdue, oncePerDay, minTripMinutes, graceMinutes, fallbackAfterDays),
        items = items,
    )

    private fun defaultItems(snoozeAB: String? = null) = listOf(
        item(1, "A", dueDay = "2026-09-01", snoozeUntilDay = snoozeAB),
        item(2, "B", dueKm = 118_000, snoozeUntilDay = snoozeAB),
        item(3, "C", dueDay = "2026-09-10"),
    )

    private fun state(
        connectedAt: Long = 1_000L,
        lastNotifiedDay: String? = null,
        prevLastNotifiedDay: String? = null,
        lastNotifiedAt: Long = -1L,
        globalSnoozeUntilDay: String? = null,
    ) = ReminderEngine.State(
        connectedAt = connectedAt,
        lastNotifiedDay = lastNotifiedDay,
        prevLastNotifiedDay = prevLastNotifiedDay,
        lastNotifiedAt = lastNotifiedAt,
        globalSnoozeUntilDay = globalSnoozeUntilDay,
    )

    private fun skipNote(d: ReminderEngine.Decision): String {
        assertIs<ReminderEngine.Decision.Skip>(d)
        return d.note
    }

    private fun names(d: ReminderEngine.Decision): List<String> {
        assertIs<ReminderEngine.Decision.Notify>(d)
        return d.names
    }

    // ------------------------------------------------------- evaluateDisconnect

    @Test
    fun e1_kisaSurusDurur() {
        val d = ReminderEngine.evaluateDisconnect(snapshot(), state(), today, durationMin = 2)
        assertEquals(ReminderEngine.NOTE_SHORT_TRIP, skipNote(d))
    }

    @Test
    fun e2_snapshotYokDurur() {
        val d = ReminderEngine.evaluateDisconnect(null, state(), today, durationMin = 25)
        assertEquals(ReminderEngine.NOTE_NO_SNAPSHOT, skipNote(d))
    }

    @Test
    fun e3_genelErtelemeDurur() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(globalSnoozeUntilDay = "2026-09-04"),
            today,
            durationMin = 25,
        )
        assertEquals(ReminderEngine.NOTE_SNOOZED, skipNote(d))
    }

    @Test
    fun e4_gecikmisYokDurur() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(items = defaultItems(snoozeAB = "2026-09-04")),
            state(),
            today,
            durationMin = 25,
        )
        assertEquals(ReminderEngine.NOTE_NO_OVERDUE, skipNote(d))
    }

    @Test
    fun e5_onlyOverdueKapaliBosListeyleBildirir() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(onlyOverdue = false, items = defaultItems(snoozeAB = "2026-09-04")),
            state(),
            today,
            durationMin = 25,
        )
        assertEquals(emptyList(), names(d))
        assertEquals("Kontroller zamanında", NotificationText.title(names(d).size))
    }

    @Test
    fun e6_gundeEnFazlaBirDurur() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(lastNotifiedDay = today),
            today,
            durationMin = 25,
        )
        assertEquals(ReminderEngine.NOTE_ONCE_PER_DAY, skipNote(d))
    }

    @Test
    fun e7_dunBildirilmisseBugunBildirir() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(lastNotifiedDay = "2026-09-02"),
            today,
            durationMin = 25,
        )
        // Sira snapshot sirasi.
        assertEquals(listOf("A", "B"), names(d))
    }

    @Test
    fun e8_esikDahilBildirir() {
        val d = ReminderEngine.evaluateDisconnect(snapshot(), state(), today, durationMin = 5)
        assertEquals(listOf("A", "B"), names(d))
    }

    @Test
    fun e9_oncePerDayKapaliAyniGunTekrarBildirir() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(oncePerDay = false),
            state(lastNotifiedDay = today),
            today,
            durationMin = 25,
        )
        assertEquals(listOf("A", "B"), names(d))
    }

    @Test
    fun e10_baglantiBilinmiyorsaKisaSurusSayilir() {
        // `onDisconnected` connectedAt < 0 iken duration 0 uretir.
        val d = ReminderEngine.evaluateDisconnect(snapshot(), state(connectedAt = -1L), today, 0)
        assertEquals(ReminderEngine.NOTE_SHORT_TRIP, skipNote(d))
    }

    // ------------------------------------------------------ ek kenar durumlar

    @Test
    fun snapshotYokkenVarsayilanMinTripUygulanir() {
        // Snapshot null iken kural okunamaz; 5 dk varsayilani gecerli.
        assertEquals(
            ReminderEngine.NOTE_SHORT_TRIP,
            skipNote(ReminderEngine.evaluateDisconnect(null, state(), today, 4)),
        )
        assertEquals(
            ReminderEngine.NOTE_NO_SNAPSHOT,
            skipNote(ReminderEngine.evaluateDisconnect(null, state(), today, 5)),
        )
    }

    @Test
    fun kisaSurusErtelemedenOnceGelir() {
        // 7.1 sirasi: minTrip kontrolu snooze kontrolunden once.
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(globalSnoozeUntilDay = "2026-09-04"),
            today,
            durationMin = 1,
        )
        assertEquals(ReminderEngine.NOTE_SHORT_TRIP, skipNote(d))
    }

    @Test
    fun bugunBitenErtelemeDurdurmaz() {
        // `> today` kosulu: bugune esit erteleme artik gecerli degil.
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(globalSnoozeUntilDay = today),
            today,
            durationMin = 25,
        )
        assertEquals(listOf("A", "B"), names(d))
    }

    @Test
    fun maddeErtelemesiBugunBitmisseGecikmisSayilir() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(items = defaultItems(snoozeAB = today)),
            state(),
            today,
            durationMin = 25,
        )
        assertEquals(listOf("A", "B"), names(d))
    }

    @Test
    fun vadesiBugunOlanMaddeGecikmisDegil() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(
                items = listOf(
                    item(1, "A", dueDay = today),
                    item(2, "B", dueKm = 118_420),
                ),
            ),
            state(),
            today,
            durationMin = 25,
        )
        assertEquals(ReminderEngine.NOTE_NO_OVERDUE, skipNote(d))
    }

    @Test
    fun ertelemeGundeEnFazlaBirdenOnceGelir() {
        val d = ReminderEngine.evaluateDisconnect(
            snapshot(),
            state(lastNotifiedDay = today, globalSnoozeUntilDay = "2026-09-04"),
            today,
            durationMin = 25,
        )
        assertEquals(ReminderEngine.NOTE_SNOOZED, skipNote(d))
    }

    // --------------------------------------------------------- evaluateConnect

    @Test
    fun r1_graceIcindeGeriBaglanma() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedDay = today, lastNotifiedAt = now - 60_000L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = now - 1_800_000L,
        )
        assertIs<ReminderEngine.ConnectDecision.Reconnect>(d)
        // Surus devam ediyor: onceki baslangic korunur, `now` degil.
        assertEquals(now - 1_800_000L, d.connectedAt)
    }

    @Test
    fun r1b_oncekiBaslangicYoksaSimdiKullanilir() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedAt = now - 30_000L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = -1L,
        )
        assertIs<ReminderEngine.ConnectDecision.Reconnect>(d)
        assertEquals(now, d.connectedAt)
    }

    @Test
    fun r2_graceDisiYeniSurus() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedAt = now - 300_000L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = now - 1_800_000L,
        )
        assertIs<ReminderEngine.ConnectDecision.Start>(d)
        assertEquals(now, d.connectedAt)
    }

    @Test
    fun r3_ciftBaglanmaOlayindaBaslangicKorunur() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = now - 600_000L, lastNotifiedAt = -1L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = -1L,
        )
        assertEquals(ReminderEngine.ConnectDecision.Keep, d)
    }

    @Test
    fun graceSiniriDahil() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedAt = now - 120_000L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = -1L,
        )
        assertIs<ReminderEngine.ConnectDecision.Reconnect>(d)
    }

    @Test
    fun grace0IseHicGeriBaglanmaYok() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedAt = now - 1L),
            graceMinutes = 0,
            now = now,
            previousTripConnectedAt = -1L,
        )
        assertIs<ReminderEngine.ConnectDecision.Start>(d)
    }

    @Test
    fun hicBildirimYokkenGeriBaglanmaYok() {
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = -1L, lastNotifiedAt = -1L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = -1L,
        )
        assertIs<ReminderEngine.ConnectDecision.Start>(d)
    }

    @Test
    fun geriBaglanmaCiftBaglanmadanOnceGelir() {
        // Denetim md. 2: grace kontrolu `connected_at` kontrolunden once.
        val now = 1_756_901_500_000L
        val d = ReminderEngine.evaluateConnect(
            state(connectedAt = now - 100L, lastNotifiedAt = now - 30_000L),
            graceMinutes = 2,
            now = now,
            previousTripConnectedAt = now - 900_000L,
        )
        assertIs<ReminderEngine.ConnectDecision.Reconnect>(d)
    }

    // ---------------------------------------------------------- arac filtresi

    @Test
    fun adresEslesmesiBuyukKucukHarfeDuyarsiz() {
        assertTrue(ReminderEngine.addressMatches(car, car.lowercase()))
        assertTrue(ReminderEngine.addressMatches(car.lowercase(), car))
    }

    @Test
    fun baskaCihazEslesmez() {
        assertFalse(ReminderEngine.addressMatches(car, "AA:BB:CC:DD:EE:FF"))
    }

    @Test
    fun aracSecilmemisseHicEslesmez() {
        // 01-spec 7.1: "Arac secilmemisse motor hicbir sey yapmaz."
        assertFalse(ReminderEngine.addressMatches(null, car))
        assertFalse(ReminderEngine.addressMatches("", car))
        assertFalse(ReminderEngine.addressMatches(car, null))
        assertFalse(ReminderEngine.addressMatches(car, ""))
    }

    // -------------------------------------------------- evaluateFallback (7.2)

    private fun fbSkip(d: ReminderEngine.FallbackDecision): String {
        assertIs<ReminderEngine.FallbackDecision.Skip>(d)
        return d.note
    }

    private fun fbNotify(
        d: ReminderEngine.FallbackDecision,
    ): ReminderEngine.FallbackDecision.Notify {
        assertIs<ReminderEngine.FallbackDecision.Notify>(d)
        return d
    }

    /** A 30 gun once gecikti, B km bazli gecikmis, C ileride. */
    private fun fallbackItems() = listOf(
        item(1, "A", dueDay = "2026-08-04"),
        item(2, "B", dueKm = 118_000),
        item(3, "C", dueDay = "2026-09-10"),
    )

    @Test
    fun f1_snapshotYokDurur() {
        assertEquals(
            ReminderEngine.NOTE_NO_SNAPSHOT,
            fbSkip(ReminderEngine.evaluateFallback(null, state(), today, null)),
        )
    }

    @Test
    fun f2_kapaliysaDurur() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(fallbackAfterDays = 0, items = fallbackItems()),
            state(),
            today,
            null,
        )
        assertEquals(ReminderEngine.SKIP_FALLBACK_OFF, fbSkip(d))
    }

    @Test
    fun f3_genelErtelemeDurur() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(globalSnoozeUntilDay = "2026-09-04"),
            today,
            null,
        )
        assertEquals(ReminderEngine.NOTE_SNOOZED, fbSkip(d))
    }

    @Test
    fun f4_yeterinceEskiGecikmeVarsaBildirir() {
        // A 30 gundur gecikmis, esik 7.
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(),
            today,
            null,
        )
        assertEquals(listOf("A"), fbNotify(d).names)
    }

    @Test
    fun f5_kmMaddesiYedegeGirmez() {
        // K-12: araba durdukca km artmaz; yalniz gun bazli gecikme sayilir.
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = listOf(item(2, "B", dueKm = 118_000))),
            state(),
            today,
            null,
        )
        assertEquals(ReminderEngine.NOTE_NO_OVERDUE, fbSkip(d))
    }

    @Test
    fun f6_gecikmeEsigeYetmezseDurur() {
        // 5 gun gecikmis, esik 7.
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = listOf(item(1, "A", dueDay = "2026-08-29"))),
            state(),
            today,
            null,
        )
        assertEquals(ReminderEngine.NOTE_NO_OVERDUE, fbSkip(d))
    }

    @Test
    fun f7_esikDahil() {
        // Tam 7 gun: 2026-08-27 -> 2026-09-03.
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = listOf(item(1, "A", dueDay = "2026-08-27"))),
            state(),
            today,
            null,
        )
        assertEquals(listOf("A"), fbNotify(d).names)
    }

    @Test
    fun f8_sonUcGunBildirimVarsaDurur() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(lastNotifiedDay = "2026-09-01"),
            today,
            null,
        )
        assertEquals(ReminderEngine.SKIP_RECENTLY_NOTIFIED, fbSkip(d))
    }

    @Test
    fun f9_ucGunGectiyseBildirir() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(lastNotifiedDay = "2026-08-31"),
            today,
            null,
        )
        assertEquals(listOf("A"), fbNotify(d).names)
    }

    @Test
    fun f10_surussuzGunSayisi() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(),
            today,
            "2026-08-25",
        )
        assertEquals(9, fbNotify(d).daysNoDrive)
        assertEquals("9 gündür sürüş yok. ", NotificationText.prefix(9))
    }

    @Test
    fun f11_hicKopmaYoksaGunSayisiBilinmiyor() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(),
            today,
            null,
        )
        assertEquals(-1, fbNotify(d).daysNoDrive)
        assertEquals("Bir süredir sürüş yok. ", NotificationText.prefix(-1))
    }

    @Test
    fun f12_ertelemeGecmisseDurdurmaz() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(items = fallbackItems()),
            state(globalSnoozeUntilDay = today),
            today,
            null,
        )
        assertEquals(listOf("A"), fbNotify(d).names)
    }

    @Test
    fun f13_maddeErtelemesiYedegiDeDurdurur() {
        val d = ReminderEngine.evaluateFallback(
            snapshot(
                items = listOf(
                    item(1, "A", dueDay = "2026-08-04", snoozeUntilDay = "2026-09-05"),
                ),
            ),
            state(),
            today,
            null,
        )
        assertEquals(ReminderEngine.NOTE_NO_OVERDUE, fbSkip(d))
    }

    @Test
    fun f14_esikDegistiginde() {
        // fallbackAfterDays 14: 9 gunluk gecikme yetmez, 30 gunluk yeter.
        val nineDays = listOf(item(1, "A", dueDay = "2026-08-25"))
        assertEquals(
            ReminderEngine.NOTE_NO_OVERDUE,
            fbSkip(
                ReminderEngine.evaluateFallback(
                    snapshot(fallbackAfterDays = 14, items = nineDays),
                    state(),
                    today,
                    null,
                ),
            ),
        )
        assertEquals(
            listOf("A"),
            fbNotify(
                ReminderEngine.evaluateFallback(
                    snapshot(fallbackAfterDays = 14, items = fallbackItems()),
                    state(),
                    today,
                    null,
                ),
            ).names,
        )
    }

    // ------------------------------------------------------------ not listesi

    @Test
    fun notlarTripNoteListesindeTanimli() {
        val documented = setOf(
            "short_trip", "no_overdue", "once_per_day", "snoozed",
            "reconnect", "fallback", "ok",
            // Denetim md. 19 uyarinca eklenenler:
            "no_snapshot", "no_permission",
        )
        val produced = setOf(
            ReminderEngine.NOTE_OK,
            ReminderEngine.NOTE_SHORT_TRIP,
            ReminderEngine.NOTE_NO_SNAPSHOT,
            ReminderEngine.NOTE_SNOOZED,
            ReminderEngine.NOTE_NO_OVERDUE,
            ReminderEngine.NOTE_ONCE_PER_DAY,
            ReminderEngine.NOTE_RECONNECT,
            ReminderEngine.NOTE_NO_PERMISSION,
            ReminderEngine.NOTE_FALLBACK,
        )
        assertTrue(documented.containsAll(produced), "beklenmeyen not: ${produced - documented}")
    }
}
