package com.beratarpa.carkeep

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Yerel saat dilimi, `yyyy-MM-dd`. String karsilastirmasi kronolojik siralamaya esittir.
 * Dart tarafindaki `date_utils.dart` ile ayni bicim (K-10).
 */
object DayKey {

    private fun fmt() = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    fun of(millis: Long): String = fmt().format(Date(millis))

    fun today(): String = of(System.currentTimeMillis())

    fun plusDays(day: String, n: Int): String {
        val c = Calendar.getInstance()
        c.time = fmt().parse(day)!!
        c.add(Calendar.DAY_OF_MONTH, n)
        return fmt().format(c.time)
    }

    /**
     * `b - a`, takvim gunu farki. Negatif farkta da dogru calisir: tam sayi bolmesi
     * sifira dogru kirpildigi icin `Math.floorDiv` kullaniliyor (aksi halde -1 gun 0 doner).
     * 12 saatlik kaydirma yaz saati gecislerini tolere eder.
     */
    fun daysBetween(a: String, b: String): Int {
        val ca = Calendar.getInstance().apply { time = fmt().parse(a)!! }
        val cb = Calendar.getInstance().apply { time = fmt().parse(b)!! }
        val diff = cb.timeInMillis - ca.timeInMillis + 12 * 3_600_000L
        return Math.floorDiv(diff, 86_400_000L).toInt()
    }
}
