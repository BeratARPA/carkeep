package com.beratarpa.carkeep

import kotlin.test.Test
import kotlin.test.assertEquals

/** Dart `date_utils.dart` ile ayni davranis (K-10). */
class DayKeyTest {

    @Test
    fun `plusDays ay ve yil sinirini geciyor`() {
        assertEquals("2026-09-04", DayKey.plusDays("2026-09-03", 1))
        assertEquals("2026-09-03", DayKey.plusDays("2026-08-20", 14))
        assertEquals("2027-01-01", DayKey.plusDays("2026-12-31", 1))
        assertEquals("2026-09-02", DayKey.plusDays("2026-09-03", -1))
    }

    @Test
    fun `daysBetween pozitif fark`() {
        assertEquals(1, DayKey.daysBetween("2026-09-03", "2026-09-04"))
        assertEquals(22, DayKey.daysBetween("2026-08-12", "2026-09-03"))
        assertEquals(306, DayKey.daysBetween("2025-11-01", "2026-09-03"))
        assertEquals(210, DayKey.daysBetween("2026-09-03", "2027-04-01"))
        assertEquals(59, DayKey.daysBetween("2026-09-03", "2026-11-01"))
    }

    @Test
    fun `daysBetween ayni gun sifir`() {
        assertEquals(0, DayKey.daysBetween("2026-09-03", "2026-09-03"))
    }

    /** Denetim notu: tam sayi bolmesi sifira kirpilirsa -1 yerine 0 donerdi. */
    @Test
    fun `daysBetween negatif fark dogru`() {
        assertEquals(-1, DayKey.daysBetween("2026-09-04", "2026-09-03"))
        assertEquals(-22, DayKey.daysBetween("2026-09-03", "2026-08-12"))
        assertEquals(-306, DayKey.daysBetween("2026-09-03", "2025-11-01"))
    }

    @Test
    fun `daysBetween artik yil`() {
        assertEquals(2, DayKey.daysBetween("2028-02-28", "2028-03-01"))
        assertEquals(1, DayKey.daysBetween("2026-02-28", "2026-03-01"))
    }

    @Test
    fun `daysBetween yaz saati gecisini tolere ediyor`() {
        assertEquals(30, DayKey.daysBetween("2026-03-15", "2026-04-14"))
        assertEquals(30, DayKey.daysBetween("2026-10-15", "2026-11-14"))
    }

    @Test
    fun `of biciminde sifir dolgu var`() {
        // 2026-01-05 12:00 yerel saat.
        val cal = java.util.Calendar.getInstance().apply {
            set(2026, 0, 5, 12, 0, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        assertEquals("2026-01-05", DayKey.of(cal.timeInMillis))
    }

    @Test
    fun `leksikografik siralama kronolojik`() {
        val keys = listOf("2026-11-01", "2026-02-03", "2025-12-31", "2027-04-01").sorted()
        assertEquals(
            listOf("2025-12-31", "2026-02-03", "2026-11-01", "2027-04-01"),
            keys,
        )
    }

    @Test
    fun `plusDays ve daysBetween tutarli`() {
        val base = "2026-09-03"
        for (n in listOf(0, 1, 3, 14, 30, 59, 210, 306, 365, 730, 1825)) {
            assertEquals(n, DayKey.daysBetween(base, DayKey.plusDays(base, n)), "n=$n")
        }
    }
}
