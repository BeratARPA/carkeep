/// Aralık ve durum hesabının **tek doğruluk kaynağı** (CLAUDE.md, K-04).
/// Kotlin tarafı hesap yapmaz; yalnız buradan üretilen `dueDay`/`dueKm`
/// değerlerini bugünle ve km ile karşılaştırır.
///
/// Kural metni: `docs/01-spec.md` §2. Yan etkisiz.
library;

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../core/format_tr.dart';
import '../core/strings_tr.dart';
import 'models/check_item.dart';
import 'models/item_status.dart';
import 'models/schedule.dart';

abstract final class StatusCalculator {
  /// [today] ve [installDay] yerel takvim günü olmalı (saat yok sayılır).
  static ItemStatus compute({
    required CheckItem item,
    required int currentKm,
    required DateTime installDay,
    required DateTime today,
  }) {
    final DateTime day0 = dateOnly(today);
    final DateTime install = dateOnly(installDay);
    final String intervalLabel = intervalTextFor(item.schedule);

    return switch (item.schedule.kind) {
      ScheduleKind.days => _days(item, day0, install, intervalLabel),
      ScheduleKind.km => _km(item, currentKm, intervalLabel),
      ScheduleKind.both => _both(item, currentKm, day0, intervalLabel),
      ScheduleKind.seasonal => _seasonal(item, day0, install, intervalLabel),
    };
  }

  // ------------------------------------------------------------------- days

  static ItemStatus _days(
    CheckItem item,
    DateTime today,
    DateTime installDay,
    String intervalLabel,
  ) {
    // §2.1: son yapılış null ise startsFromInstall=true → kurulum gününden say.
    final DateTime? base = tryParseDay(item.lastDoneDay) ??
        (item.startsFromInstall ? installDay : null);
    if (base == null) {
      return _unknown(intervalLabel);
    }

    final int interval = item.schedule.intervalDays!;
    final DateTime due = addDays(base, interval);
    final int daysLeft = daysBetween(today, due);

    return _fromDays(
      item: item,
      today: today,
      due: due,
      daysLeft: daysLeft,
      interval: interval,
      soonThreshold: kSoonDays,
      intervalLabel: intervalLabel,
      dueKm: null,
    );
  }

  // --------------------------------------------------------------------- km

  static ItemStatus _km(CheckItem item, int currentKm, String intervalLabel) {
    // §2.1: servis geçmişi bilinmeden hesap yok.
    if (item.lastDoneKm == null) {
      return _unknown(intervalLabel);
    }

    final int interval = item.schedule.intervalKm!;
    final int dueKm = item.lastDoneKm! + interval;
    final int kmLeft = dueKm - currentKm;

    return _fromKm(
      item: item,
      dueKm: dueKm,
      kmLeft: kmLeft,
      interval: interval,
      intervalLabel: intervalLabel,
      dueDay: null,
      today: null,
    );
  }

  // ------------------------------------------------------------------- both

  static ItemStatus _both(
    CheckItem item,
    int currentKm,
    DateTime today,
    String intervalLabel,
  ) {
    final DateTime? baseDay = tryParseDay(item.lastDoneDay);
    // §2.1: `both`ta son yapılış null → unknown. İki yarıdan biri eksikse de
    // hesap yapılamaz (spec bu durumu ayrıca tanımlamıyor; ILERLEME notu).
    if (baseDay == null || item.lastDoneKm == null) {
      return _unknown(intervalLabel);
    }

    final int intervalDays = item.schedule.intervalDays!;
    final int intervalKm = item.schedule.intervalKm!;

    final DateTime due = addDays(baseDay, intervalDays);
    final int daysLeft = daysBetween(today, due);
    final int dueKm = item.lastDoneKm! + intervalKm;
    final int kmLeft = dueKm - currentKm;

    // §2.2: bağlayıcı boyut, oranı küçük olan. Eşitse km.
    final double kmRatio = kmLeft / intervalKm;
    final double dayRatio = daysLeft / intervalDays;
    final bool kmBinds = kmRatio <= dayRatio;

    return kmBinds
        ? _fromKm(
            item: item,
            dueKm: dueKm,
            kmLeft: kmLeft,
            interval: intervalKm,
            intervalLabel: intervalLabel,
            dueDay: dayKey(due),
            today: today,
            daysLeft: daysLeft,
          )
        : _fromDays(
            item: item,
            today: today,
            due: due,
            daysLeft: daysLeft,
            interval: intervalDays,
            soonThreshold: kSoonDays,
            intervalLabel: intervalLabel,
            dueKm: dueKm,
            kmLeft: kmLeft,
          );
  }

  // --------------------------------------------------------------- seasonal

  static ItemStatus _seasonal(
    CheckItem item,
    DateTime today,
    DateTime installDay,
    String intervalLabel,
  ) {
    // §2.1: vade = son yapılıştan (null ise kurulum günü − 1) **sonraki ilk**
    // tarih. `startsFromInstall`ın mevsimselde rolü tanımlı değil; spec'in
    // koşulsuz ifadesi uygulanıyor (ILERLEME notu).
    final DateTime? lastDone = tryParseDay(item.lastDoneDay);
    final DateTime after = lastDone ?? addDays(installDay, -1);
    DateTime due = nextSeasonalDate(item.schedule.dates, after);

    // K-29: mevsimsel işi tarihinden birkaç gün önce yapmak normaldir (20 Eki'de
    // kışlık lastik). Ham kural o tarihi hâlâ "yaklaşan" gösterip kullanıcıyı
    // yaptığı işe tekrar çağırıyordu. Son yapılış, vadeye `kSoonSeasonalDays`
    // içindeyse o tarih yapılmış sayılır ve sıradaki tarihe geçilir.
    //
    // Yalnız gerçek son yapılışta: kurulum günü yedeği bir iş yapıldığı anlamına
    // gelmez (25 Eki'de kurulan uygulama 1 Kas'ı atlamamalı).
    if (lastDone != null && daysBetween(lastDone, due) <= kSoonSeasonalDays) {
      due = nextSeasonalDate(item.schedule.dates, due);
    }

    final int daysLeft = daysBetween(today, due);

    return _fromDays(
      item: item,
      today: today,
      due: due,
      daysLeft: daysLeft,
      // K-17: mevsimselin aralığı yok; sıralama oranı için bölen 365.
      interval: 365,
      soonThreshold: kSoonSeasonalDays,
      intervalLabel: intervalLabel,
      dueKm: null,
    );
  }

  // ------------------------------------------------------------ ortak kurma

  static ItemStatus _fromDays({
    required CheckItem item,
    required DateTime today,
    required DateTime due,
    required int daysLeft,
    required int interval,
    required int soonThreshold,
    required String intervalLabel,
    required int? dueKm,
    int? kmLeft,
  }) {
    final double sortKey = daysLeft / interval;
    final bool snoozed = _isSnoozed(item, today);

    final ItemState state;
    final String short;
    if (daysLeft < 0) {
      if (snoozed) {
        state = ItemState.soon;
        short = S.tomorrow;
      } else {
        state = ItemState.overdue;
        short = overdueDaysText(-daysLeft);
      }
    } else if (daysLeft <= soonThreshold) {
      state = ItemState.soon;
      short = soonDaysText(daysLeft);
    } else {
      state = ItemState.ok;
      short = formatDate(due, refYear: today.year);
    }

    return ItemStatus(
      state: state,
      dueDay: dayKey(due),
      dueKm: dueKm,
      daysLeft: daysLeft,
      kmLeft: kmLeft,
      binding: BindingDim.days,
      shortText: short,
      longText: longStatusText(short, intervalLabel),
      sortKey: sortKey,
      // K-22: gün bağlayıcıysa yakınlık doğrudan kalan gün.
      proximityKey: daysLeft.toDouble(),
    );
  }

  static ItemStatus _fromKm({
    required CheckItem item,
    required int dueKm,
    required int kmLeft,
    required int interval,
    required String intervalLabel,
    required String? dueDay,
    required DateTime? today,
    int? daysLeft,
  }) {
    final double sortKey = kmLeft / interval;
    final bool snoozed = today != null && _isSnoozed(item, today);

    final ItemState state;
    final String short;
    if (kmLeft < 0) {
      if (snoozed) {
        state = ItemState.soon;
        short = S.tomorrow;
      } else {
        state = ItemState.overdue;
        short = overdueKmText(-kmLeft);
      }
    } else if (kmLeft <= kSoonKm) {
      state = ItemState.soon;
      short = kmLeftText(kmLeft);
    } else {
      state = ItemState.ok;
      short = kmLeftText(kmLeft);
    }

    return ItemStatus(
      state: state,
      dueDay: dueDay,
      dueKm: dueKm,
      daysLeft: daysLeft,
      kmLeft: kmLeft,
      binding: BindingDim.km,
      shortText: short,
      longText: longStatusText(short, intervalLabel),
      sortKey: sortKey,
      // K-22: km maddesi gün ölçeğine çevrilir; varsayım yalnız sıralamada.
      proximityKey: kmLeft / kAssumedKmPerDay,
    );
  }

  static ItemStatus _unknown(String intervalLabel) => ItemStatus(
    state: ItemState.unknown,
    shortText: S.enterDate,
    longText: longStatusText(S.enterDate, intervalLabel),
    // `unknown` şablon sırasını korur, hiçbir sıralamaya girmez.
    sortKey: double.infinity,
    proximityKey: double.infinity,
  );

  /// §2.3 md. 5: erteleme yalnız gecikmiş maddeyi etkiler ve yalnız
  /// `snoozeUntilDay > today` iken.
  static bool _isSnoozed(CheckItem item, DateTime today) {
    final String? until = item.snoozeUntilDay;
    return until != null && until.compareTo(dayKey(today)) > 0;
  }
}

/// [dates] içinden [after] gününden **kesin sonraki** ilk tarih. Yıl sınırını
/// geçer; `2026-11-01` için son yapılış aynı gün ise sonraki yılın ilk tarihi.
DateTime nextSeasonalDate(List<SeasonalDate> dates, DateTime after) {
  final DateTime a = dateOnly(after);
  DateTime? best;
  for (int yearOffset = 0; yearOffset <= 1; yearOffset++) {
    for (final SeasonalDate d in dates) {
      final DateTime candidate = DateTime(a.year + yearOffset, d.month, d.day);
      if (candidate.isAfter(a) && (best == null || candidate.isBefore(best))) {
        best = candidate;
      }
    }
  }
  // `dates` boş olamaz (Schedule.seasonal doğruluyor); yine de savunmacı.
  return best ?? addDays(a, 1);
}

/// Maddenin aralık metni (01-spec §2.4).
String intervalTextFor(Schedule schedule) => intervalText(
  intervalDays: schedule.kind == ScheduleKind.seasonal
      ? null
      : schedule.intervalDays,
  intervalKm: schedule.intervalKm,
  seasonalDates: schedule.kind == ScheduleKind.seasonal
      ? <({int day, int month})>[
          for (final SeasonalDate d in schedule.dates)
            (month: d.month, day: d.day),
        ]
      : null,
);
