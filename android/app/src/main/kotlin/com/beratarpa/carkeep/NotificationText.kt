package com.beratarpa.carkeep

/**
 * Bildirim metinleri (01-spec 3.8). Kullaniciya gorunen Turkce metinler
 * normalde `lib/core/strings_tr.dart`'ta; bildirimi Kotlin bastigi ve
 * receiver Flutter motorunu uyandirmadigi icin (K-03) bu dort metin burada
 * duruyor. Baska yerde bildirim metni yazilmaz.
 *
 * Saf: Android API kullanmaz, JVM testlerinden dogrudan cagrilir.
 */
object NotificationText {

    /** 01-spec 3.8: ilk kac madde adi metinde sayilir. */
    const val PREVIEW_COUNT = 3

    fun title(overdueCount: Int): String =
        if (overdueCount == 0) "Kontroller zamanında" else "$overdueCount kontrol gecikti"

    /** Yalniz yedek (surussuz) bildirimde dolu. */
    fun prefix(daysNoDrive: Int?): String = when {
        daysNoDrive == null -> ""
        daysNoDrive > 0 -> "$daysNoDrive gündür sürüş yok. "
        else -> "Bir süredir sürüş yok. "
    }

    /** Katlanmis bildirim metni: ilk uc ad, fazlasi " ve n daha". */
    fun short(names: List<String>): String = when {
        names.isEmpty() -> "Gecikmiş bir şey yok."
        names.size <= PREVIEW_COUNT -> names.joinToString(", ")
        else -> names.take(PREVIEW_COUNT).joinToString(", ") +
            " ve ${names.size - PREVIEW_COUNT} daha"
    }

    /** `BigTextStyle`: tum adlar satir satir + kapanis cumlesi. */
    fun big(names: List<String>, daysNoDrive: Int? = null): String {
        val prefix = prefix(daysNoDrive)
        // Denetim (kucuk not): liste bosken bos `bigText` kuruluyordu.
        if (names.isEmpty()) return prefix + short(names)
        return prefix + names.joinToString("\n") +
            "\nArabanın yanındayken birkaç dakika sürer."
    }

    fun contentText(names: List<String>, daysNoDrive: Int? = null): String =
        prefix(daysNoDrive) + short(names)
}
