package com.beratarpa.carkeep

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

/** 01-spec 3.8 bildirim metinleri. */
class NotificationTextTest {

    @Test
    fun baslikSayiyaGoreDegisir() {
        assertEquals("1 kontrol gecikti", NotificationText.title(1))
        assertEquals("2 kontrol gecikti", NotificationText.title(2))
        assertEquals("Kontroller zamanında", NotificationText.title(0))
    }

    @Test
    fun ucVeAltiVirgulleListelenir() {
        assertEquals("A", NotificationText.short(listOf("A")))
        assertEquals("A, B, C", NotificationText.short(listOf("A", "B", "C")))
    }

    @Test
    fun ucustuFazlasiSayiyaDoner() {
        assertEquals(
            "A, B, C ve 2 daha",
            NotificationText.short(listOf("A", "B", "C", "D", "E")),
        )
        assertEquals(
            "A, B, C ve 1 daha",
            NotificationText.short(listOf("A", "B", "C", "D")),
        )
    }

    @Test
    fun bosListeMetni() {
        assertEquals("Gecikmiş bir şey yok.", NotificationText.short(emptyList()))
    }

    @Test
    fun bigTextTumAdlariVeKapanisiIcerir() {
        assertEquals(
            "A\nB\nArabanın yanındayken birkaç dakika sürer.",
            NotificationText.big(listOf("A", "B")),
        )
    }

    @Test
    fun bigTextBosListedeBosDegil() {
        // Denetim (kucuk not): eskiden bos string ile kuruluyordu.
        val big = NotificationText.big(emptyList())
        assertFalse(big.isEmpty())
        assertEquals("Gecikmiş bir şey yok.", big)
    }

    @Test
    fun yedekBildirimOnEki() {
        assertEquals("", NotificationText.prefix(null))
        assertEquals("9 gündür sürüş yok. ", NotificationText.prefix(9))
        assertEquals("Bir süredir sürüş yok. ", NotificationText.prefix(-1))
        assertEquals("Bir süredir sürüş yok. ", NotificationText.prefix(0))
    }

    @Test
    fun yedekBildirimMetniOnEkiIcerir() {
        assertEquals(
            "9 gündür sürüş yok. A, B",
            NotificationText.contentText(listOf("A", "B"), daysNoDrive = 9),
        )
        assertEquals(
            "9 gündür sürüş yok. A\nB\nArabanın yanındayken birkaç dakika sürer.",
            NotificationText.big(listOf("A", "B"), daysNoDrive = 9),
        )
    }
}
