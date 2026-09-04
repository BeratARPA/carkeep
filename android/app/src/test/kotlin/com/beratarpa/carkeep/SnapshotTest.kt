package com.beratarpa.carkeep

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Saf JVM testleri (07 9): Android sinifi kullanilmiyor, Robolectric yok.
 * `org.json` host tarafinda `testImplementation` ile geliyor.
 */
class SnapshotTest {

    private val today = "2026-09-03"

    private fun json(items: String, km: Long = 118420, address: String = "\"00:11:22:33:44:55\"") =
        """
        {
          "version": 1,
          "generatedAt": "2026-09-03T14:05:12+03:00",
          "car": { "address": $address, "name": "Uconnect", "km": $km },
          "rules": { "onlyOverdue": true, "oncePerDay": true, "minTripMinutes": 5,
                     "graceMinutes": 2, "fallbackAfterDays": 7 },
          "items": [$items]
        }
        """.trimIndent()

    @Test
    fun `bos ve bozuk girdide null doner`() {
        assertNull(Snapshot.parse(null))
        assertNull(Snapshot.parse(""))
        assertNull(Snapshot.parse("{ bu json degil"))
        assertNull(Snapshot.parse("[]"))
        assertNull(Snapshot.parse("{}"))
    }

    @Test
    fun `kok alanlar okunuyor`() {
        val s = Snapshot.parse(json(""))!!
        assertEquals(1, s.version)
        assertEquals("00:11:22:33:44:55", s.carAddress)
        assertEquals("Uconnect", s.carName)
        assertEquals(118420L, s.km)
        assertEquals(Rules.DEFAULTS, s.rules)
        assertTrue(s.items.isEmpty())
    }

    /**
     * Denetim md. 1: `optString` bir JSON null icin `"null"` metnini dondurur.
     * Bu test o hatanin geri gelmesini engeller.
     */
    @Test
    fun `JSON null degerleri gercek null olarak okunuyor`() {
        val s = Snapshot.parse(
            json("""{ "id": 12, "name": "Motor yagi", "dueDay": "2026-08-26",
                      "dueKm": null, "snoozeUntilDay": null }""")
        )!!
        val item = s.items.single()
        assertNull(item.dueKm)
        assertNull(item.snoozeUntilDay)
        assertEquals("2026-08-26", item.dueDay)
    }

    @Test
    fun `snoozeUntilDay null iken madde ertelenmis sayilmiyor`() {
        val s = Snapshot.parse(
            json("""{ "id": 12, "name": "Motor yagi", "dueDay": "2026-08-26",
                      "dueKm": null, "snoozeUntilDay": null }""")
        )!!
        assertFalse(s.items.single().isSnoozed(today))
        assertEquals(1, s.overdueItems(today).size)
    }

    @Test
    fun `dueDay null olan km maddesi gun uzerinden gecikmis sayilmiyor`() {
        val s = Snapshot.parse(
            json("""{ "id": 18, "name": "Hava filtresi", "dueDay": null,
                      "dueKm": 130000, "snoozeUntilDay": null }""")
        )!!
        val item = s.items.single()
        assertNull(item.dueDay)
        assertEquals(130000L, item.dueKm)
        assertFalse(item.isOverdue(today, 118420L))
    }

    @Test
    fun `car address null okunabiliyor`() {
        val s = Snapshot.parse(json("", address = "null"))!!
        assertNull(s.carAddress)
    }

    @Test
    fun `gun uzerinden gecikmis tespiti`() {
        val item = SnapshotItem(1, "A", "2026-09-01", null, null)
        assertTrue(item.isOverdue(today, 0))
        assertFalse(SnapshotItem(1, "A", "2026-09-03", null, null).isOverdue(today, 0))
        assertFalse(SnapshotItem(1, "A", "2026-09-10", null, null).isOverdue(today, 0))
    }

    @Test
    fun `km uzerinden gecikmis tespiti`() {
        val item = SnapshotItem(2, "B", null, 118000L, null)
        assertTrue(item.isOverdue(today, 118420L))
        assertFalse(SnapshotItem(2, "B", null, 118420L, null).isOverdue(today, 118420L))
        assertFalse(SnapshotItem(2, "B", null, 119000L, null).isOverdue(today, 118420L))
    }

    @Test
    fun `both maddede iki boyuttan biri yeterli`() {
        val onlyKm = SnapshotItem(3, "C", "2026-12-01", 118000L, null)
        assertTrue(onlyKm.isOverdue(today, 118420L))
        val onlyDay = SnapshotItem(3, "C", "2026-09-01", 130000L, null)
        assertTrue(onlyDay.isOverdue(today, 118420L))
    }

    @Test
    fun `ertelenmis madde gecikmis listesinden cikiyor`() {
        val s = Snapshot.parse(
            json(
                """{ "id": 1, "name": "A", "dueDay": "2026-09-01", "dueKm": null,
                     "snoozeUntilDay": "2026-09-04" },
                   { "id": 2, "name": "B", "dueDay": "2026-09-01", "dueKm": null,
                     "snoozeUntilDay": "2026-09-03" }"""
            )
        )!!
        val overdue = s.overdueItems(today)
        assertEquals(listOf(2L), overdue.map { it.id })
    }

    @Test
    fun `gecikmis liste snapshot sirasini koruyor`() {
        val s = Snapshot.parse(
            json(
                """{ "id": 5, "name": "A", "dueDay": "2026-09-01", "dueKm": null, "snoozeUntilDay": null },
                   { "id": 3, "name": "B", "dueDay": null, "dueKm": 118000, "snoozeUntilDay": null },
                   { "id": 9, "name": "C", "dueDay": "2026-09-10", "dueKm": null, "snoozeUntilDay": null }"""
            )
        )!!
        assertEquals(listOf(5L, 3L), s.overdueItems(today).map { it.id })
        assertEquals(listOf("A", "B"), s.overdueItems(today).map { it.name })
    }

    @Test
    fun `eksik kural alanlari varsayilana dusuyor`() {
        val s = Snapshot.parse(
            """
            { "version": 1, "car": { "address": null, "name": null, "km": 100 },
              "rules": { "minTripMinutes": 12 }, "items": [] }
            """.trimIndent()
        )!!
        assertEquals(12, s.rules.minTripMinutes)
        assertEquals(Rules.DEFAULTS.graceMinutes, s.rules.graceMinutes)
        assertEquals(Rules.DEFAULTS.onlyOverdue, s.rules.onlyOverdue)
    }

    @Test
    fun `parseCarAddress kisayolu`() {
        assertEquals("00:11:22:33:44:55", Snapshot.parseCarAddress(json("")))
        assertNull(Snapshot.parseCarAddress(json("", address = "null")))
        assertNull(Snapshot.parseCarAddress("bozuk"))
    }
    /** K-30: alan yoksa varsayilan (kapali) — eski snapshot'lar bozulmaz. */
    @Test
    fun `requireMotion eksikse kapali gelir`() {
        val snap = Snapshot.parse(json(""))
        assertNotNull(snap)
        assertFalse(snap.rules.requireMotion)
    }

    @Test
    fun `requireMotion true okunur`() {
        val raw = json("").replace(
            "\"fallbackAfterDays\": 7",
            "\"fallbackAfterDays\": 7, \"requireMotion\": true",
        )
        val snap = Snapshot.parse(raw)
        assertNotNull(snap)
        assertTrue(snap.rules.requireMotion)
    }
}
