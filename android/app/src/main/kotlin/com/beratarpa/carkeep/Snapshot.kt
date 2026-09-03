package com.beratarpa.carkeep

import org.json.JSONObject

/**
 * Dart'in yazdigi snapshot (02-mimari 5). Kotlin **hesap yapmaz** (K-04):
 * yalnizca `dueDay < today` ve `dueKm < km` karsilastirir.
 *
 * Saf sinif: Android API kullanmaz, JVM testlerinden dogrudan cagrilir (07 9).
 */
data class SnapshotItem(
    val id: Long,
    val name: String,
    val dueDay: String?,
    val dueKm: Long?,
    val snoozeUntilDay: String?,
) {
    /** `yyyy-MM-dd` leksikografik karsilastirma = kronolojik (K-10). */
    fun isOverdue(today: String, km: Long): Boolean =
        (dueDay != null && dueDay < today) || (dueKm != null && dueKm < km)

    fun isSnoozed(today: String): Boolean =
        snoozeUntilDay != null && snoozeUntilDay > today
}

data class Rules(
    val onlyOverdue: Boolean,
    val oncePerDay: Boolean,
    val minTripMinutes: Int,
    val graceMinutes: Int,
    val fallbackAfterDays: Int,
) {
    companion object {
        val DEFAULTS = Rules(
            onlyOverdue = true,
            oncePerDay = true,
            minTripMinutes = 5,
            graceMinutes = 2,
            fallbackAfterDays = 7,
        )
    }
}

data class Snapshot(
    val version: Int,
    val carAddress: String?,
    val carName: String?,
    val km: Long,
    val rules: Rules,
    val items: List<SnapshotItem>,
) {
    fun overdueItems(today: String): List<SnapshotItem> =
        items.filter { it.isOverdue(today, km) && !it.isSnoozed(today) }

    companion object {

        /**
         * Bozuk veya eksik JSON'da `null` doner; cagiran taraf bunu
         * `no_snapshot` olarak isler.
         *
         * DIKKAT: `optString` bir JSON `null` degeri icin bos string degil,
         * `"null"` **metnini** dondurur (org.json davranisi). Bu yuzden her
         * nullable alan `isNull(key)` ile kontrol ediliyor. Aksi halde
         * `snoozeUntilDay == "null"` olur, `"null" > "2026-09-03"` dogru cikar
         * ve hicbir madde gecikmis sayilmaz, yani hic bildirim gelmez.
         */
        fun parse(json: String?): Snapshot? {
            if (json.isNullOrEmpty()) return null
            return try {
                val o = JSONObject(json)
                val car = o.getJSONObject("car")
                val r = o.getJSONObject("rules")
                val arr = o.getJSONArray("items")
                val items = ArrayList<SnapshotItem>(arr.length())
                for (i in 0 until arr.length()) {
                    val it = arr.getJSONObject(i)
                    items.add(
                        SnapshotItem(
                            id = it.getLong("id"),
                            name = it.getString("name"),
                            dueDay = nullableString(it, "dueDay"),
                            dueKm = nullableLong(it, "dueKm"),
                            snoozeUntilDay = nullableString(it, "snoozeUntilDay"),
                        )
                    )
                }
                Snapshot(
                    version = o.optInt("version", 1),
                    carAddress = nullableString(car, "address"),
                    carName = nullableString(car, "name"),
                    km = car.getLong("km"),
                    rules = Rules(
                        onlyOverdue = r.optBoolean("onlyOverdue", Rules.DEFAULTS.onlyOverdue),
                        oncePerDay = r.optBoolean("oncePerDay", Rules.DEFAULTS.oncePerDay),
                        minTripMinutes = r.optInt("minTripMinutes", Rules.DEFAULTS.minTripMinutes),
                        graceMinutes = r.optInt("graceMinutes", Rules.DEFAULTS.graceMinutes),
                        fallbackAfterDays = r.optInt(
                            "fallbackAfterDays",
                            Rules.DEFAULTS.fallbackAfterDays,
                        ),
                    ),
                    items = items,
                )
            } catch (e: Exception) {
                null
            }
        }

        /** Yalniz `car.address`; `writeSnapshot` bunu prefs'e kopyalar. */
        fun parseCarAddress(json: String?): String? = parse(json)?.carAddress

        private fun nullableString(o: JSONObject, key: String): String? {
            if (!o.has(key) || o.isNull(key)) return null
            val v = o.optString(key, "")
            return if (v.isEmpty()) null else v
        }

        private fun nullableLong(o: JSONObject, key: String): Long? {
            if (!o.has(key) || o.isNull(key)) return null
            return o.optLong(key)
        }
    }
}
