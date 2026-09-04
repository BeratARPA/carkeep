/// `docs/06-test-plani.md` §1 tablosundaki **her satır** ayrı test (T04 kabul
/// kriteri). Satır numaraları test adlarında.
///
/// Sabitler: today = 2026-09-03, currentKm = 118.420, installDay = 2026-08-20,
/// soonDays = 3, soonKm = 1000, soonSeasonalDays = 14, mevsimsel [1 Kas, 1 Nis].
library;

import 'package:carkeep/domain/models/check_item.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/domain/status_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime kToday = DateTime(2026, 9, 3);
const int kCurrentKm = 118420;
final DateTime kInstallDay = DateTime(2026, 8, 20);

final List<SeasonalDate> kSeasonalDates = <SeasonalDate>[
  const SeasonalDate(11, 1),
  const SeasonalDate(4, 1),
];

CheckItem item({
  required Schedule schedule,
  String? lastDoneDay,
  int? lastDoneKm,
  bool startsFromInstall = false,
  String? snoozeUntilDay,
  String name = 'Madde',
  int id = 1,
  bool enabled = true,
  int sortOrder = 0,
}) {
  return CheckItem(
    id: id,
    templateKey: 'k$id',
    name: name,
    groupKey: 'monthly',
    schedule: schedule,
    measure: const Measure.none(),
    why: '',
    how: const <String>[],
    warn: null,
    sourceNote: null,
    verified: 'true',
    startsFromInstall: startsFromInstall,
    appliesLastService: false,
    enabled: enabled,
    sortOrder: sortOrder,
    lastDoneDay: lastDoneDay,
    lastDoneKm: lastDoneKm,
    lastValue: null,
    snoozeUntilDay: snoozeUntilDay,
  );
}

ItemStatus status(
  CheckItem i, {
  DateTime? today,
  int? currentKm,
  DateTime? installDay,
}) {
  return StatusCalculator.compute(
    item: i,
    currentKm: currentKm ?? kCurrentKm,
    installDay: installDay ?? kInstallDay,
    today: today ?? kToday,
  );
}

void main() {
  group('§1 tablosu — days', () {
    test('#1 days 14, son 2026-08-12 → overdue, daysLeft −8', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-12'),
      );
      expect(s.state, ItemState.overdue);
      expect(s.daysLeft, -8);
      expect(s.dueDay, '2026-08-26');
      expect(s.shortText, '8 gün gecikti');
      expect(s.longText, '8 gün gecikti. 14 günde bir.');
    });

    test('#2 days 14, son 2026-08-31 → ok, daysLeft 11', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-31'),
      );
      expect(s.state, ItemState.ok);
      expect(s.daysLeft, 11);
      expect(s.dueDay, '2026-09-14');
      expect(s.shortText, '14 Eyl');
      expect(s.longText, '14 Eyl. 14 günde bir.');
    });

    test('#3 days 14, son 2026-08-21 → soon, daysLeft 1', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-21'),
      );
      expect(s.state, ItemState.soon);
      expect(s.daysLeft, 1);
      expect(s.shortText, '1 gün kaldı');
    });

    test('#4 days 14, son 2026-08-20 → soon, daysLeft 0, "Bugün"', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-20'),
      );
      expect(s.state, ItemState.soon);
      expect(s.daysLeft, 0);
      expect(s.shortText, 'Bugün');
    });

    test('#5 days 14, son null, startsFromInstall → soon, daysLeft 0', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), startsFromInstall: true),
      );
      expect(s.state, ItemState.soon);
      expect(s.daysLeft, 0);
      expect(s.dueDay, '2026-09-03');
      expect(s.shortText, 'Bugün');
    });

    test('#6 days 14, son null, startsFromInstall=false → unknown', () {
      final ItemStatus s = status(item(schedule: Schedule.days(14)));
      expect(s.state, ItemState.unknown);
      expect(s.shortText, 'Tarih gir');
      expect(s.longText, 'Tarih gir. 14 günde bir.');
      expect(s.dueDay, isNull);
      expect(s.dueKm, isNull);
    });

    test('#7 days 30, son 2026-08-05 → soon, daysLeft 1', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(30), lastDoneDay: '2026-08-05'),
      );
      expect(s.state, ItemState.soon);
      expect(s.daysLeft, 1);
      expect(s.shortText, '1 gün kaldı');
      expect(s.longText, '1 gün kaldı. Ayda bir.');
    });

    test('#8 days 730, son 2025-09-16 → ok, farklı yıl metni', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(730), lastDoneDay: '2025-09-16'),
      );
      expect(s.state, ItemState.ok);
      expect(s.dueDay, '2027-09-16');
      expect(s.shortText, '16 Eyl 2027');
      expect(s.longText, '16 Eyl 2027. 2 yılda bir.');
    });
  });

  group('§1 tablosu — km', () {
    test('#9 km 30.000, son km 100.000 → ok, kmLeft 11.580', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 100000),
      );
      expect(s.state, ItemState.ok);
      expect(s.kmLeft, 11580);
      expect(s.dueKm, 130000);
      expect(s.shortText, '11.580 km kaldı');
      expect(s.longText, "11.580 km kaldı. 30.000 km'de bir.");
    });

    test('#10 km 30.000, son km 88.000 → overdue, kmLeft −420', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 88000),
      );
      expect(s.state, ItemState.overdue);
      expect(s.kmLeft, -420);
      expect(s.shortText, '420 km geçti');
    });

    test('#11 km 30.000, son km 89.000 → soon, kmLeft 580', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 89000),
      );
      expect(s.state, ItemState.soon);
      expect(s.kmLeft, 580);
      expect(s.shortText, '580 km kaldı');
    });

    test('#12 km 30.000, son km 89.420 → soon, kmLeft 1.000 (eşik dahil)', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 89420),
      );
      expect(s.state, ItemState.soon);
      expect(s.kmLeft, 1000);
      expect(s.shortText, '1.000 km kaldı');
    });

    test('#13 km 30.000, son null → unknown', () {
      final ItemStatus s = status(item(schedule: Schedule.km(30000)));
      expect(s.state, ItemState.unknown);
      expect(s.shortText, 'Tarih gir');
    });
  });

  group('§1 tablosu — both', () {
    Schedule oilChange() => Schedule.both(days: 365, km: 15000);

    test('#14 both, 2026-03-12 / 104.900 → ok, km bağlayıcı, kmLeft 1.480', () {
      final ItemStatus s = status(
        item(
          schedule: oilChange(),
          lastDoneDay: '2026-03-12',
          lastDoneKm: 104900,
        ),
      );
      expect(s.state, ItemState.ok);
      expect(s.binding, BindingDim.km);
      expect(s.kmLeft, 1480);
      expect(s.dueKm, 119900);
      expect(s.dueDay, '2027-03-12');
      expect(s.shortText, '1.480 km kaldı');
      expect(s.longText, "1.480 km kaldı. 15.000 km'de bir veya yılda bir.");
    });

    test('#15 both, 2025-09-10 / 110.000 → ok, gün bağlayıcı, daysLeft 7', () {
      final ItemStatus s = status(
        item(
          schedule: oilChange(),
          lastDoneDay: '2025-09-10',
          lastDoneKm: 110000,
        ),
      );
      expect(s.state, ItemState.ok);
      expect(s.binding, BindingDim.days);
      expect(s.daysLeft, 7);
      expect(s.shortText, '10 Eyl');
    });

    test('#16 both, 2025-08-20 / 110.000 → overdue, gün bağlayıcı, −14', () {
      final ItemStatus s = status(
        item(
          schedule: oilChange(),
          lastDoneDay: '2025-08-20',
          lastDoneKm: 110000,
        ),
      );
      expect(s.state, ItemState.overdue);
      expect(s.binding, BindingDim.days);
      expect(s.daysLeft, -14);
      expect(s.shortText, '14 gün gecikti');
    });

    test('#17 both, 2026-01-01 / 103.000 → overdue, km bağlayıcı, −420', () {
      final ItemStatus s = status(
        item(
          schedule: oilChange(),
          lastDoneDay: '2026-01-01',
          lastDoneKm: 103000,
        ),
      );
      expect(s.state, ItemState.overdue);
      expect(s.binding, BindingDim.km);
      expect(s.kmLeft, -420);
      expect(s.shortText, '420 km geçti');
    });

    test('#18 both 1.000/100, oranlar eşit → km bağlayıcı, kmLeft 900', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.both(days: 100, km: 1000),
          lastDoneDay: '2026-08-24',
          lastDoneKm: 118320,
        ),
      );
      expect(s.state, ItemState.soon);
      expect(s.binding, BindingDim.km);
      expect(s.kmLeft, 900);
      expect(s.daysLeft, 90);
      expect(s.shortText, '900 km kaldı');
    });

    test('#19 both, son null → unknown', () {
      final ItemStatus s = status(item(schedule: oilChange()));
      expect(s.state, ItemState.unknown);
      expect(s.shortText, 'Tarih gir');
    });
  });

  group('§1 tablosu — erteleme', () {
    test('#20 overdue + snooze yarına → soon, "Yarın"', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          snoozeUntilDay: '2026-09-04',
        ),
      );
      expect(s.state, ItemState.soon);
      expect(s.shortText, 'Yarın');
      expect(s.longText, 'Yarın. 14 günde bir.');
      expect(s.daysLeft, -8);
    });

    test('#21 overdue + snooze bugüne → hâlâ overdue', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          snoozeUntilDay: '2026-09-03',
        ),
      );
      expect(s.state, ItemState.overdue);
      expect(s.shortText, '8 gün gecikti');
    });

    test('#22 ok + snooze → erteleme yalnız overdue\'yu etkiler', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-31',
          snoozeUntilDay: '2026-09-04',
        ),
      );
      expect(s.state, ItemState.ok);
      expect(s.shortText, '14 Eyl');
    });
  });

  group('§1 tablosu — seasonal', () {
    Schedule seasonal() => Schedule.seasonal(kSeasonalDates);

    test('#23 son 2026-04-05 → ok, vade 1 Kas, daysLeft 59', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-04-05'),
      );
      expect(s.state, ItemState.ok);
      expect(s.dueDay, '2026-11-01');
      expect(s.daysLeft, 59);
      expect(s.shortText, '1 Kas');
      expect(s.longText, '1 Kas. Her yıl 1 Kas ve 1 Nis.');
    });

    test('#24 son 2025-10-20 → overdue, vade 2026-04-01 (K-29)', () {
      // 06 §1 satır 24 vade olarak 2025-11-01 ve −306 gün bekliyordu. K-29 ile
      // değişti: 20 Eki'de yapılan iş 1 Kas 2025 değişimiydi; onu tekrar
      // istemek yerine sıradaki tarihe (1 Nis 2026) geçiyoruz. Kaçırılan gerçek
      // iş o.
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2025-10-20'),
      );
      expect(s.state, ItemState.overdue);
      expect(s.dueDay, '2026-04-01');
      expect(s.daysLeft, -155);
      expect(s.shortText, '155 gün gecikti');
    });

    // ------------------------------------------------------------------ K-29

    test('tarihinden 12 gün önce yapılırsa sıradaki tarihe geçer', () {
      // 20 Eki'de kışlık lastik takıldı; vade 1 Kas değil, 1 Nis olmalı.
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-10-20'),
      );
      expect(s.dueDay, '2027-04-01');
    });

    test('eşik dahil: tam 14 gün önce', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-10-18'),
      );
      expect(s.dueDay, '2027-04-01');
    });

    test('eşiğin dışında: 15 gün önce vadeyi ilerletmez', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-10-17'),
      );
      expect(s.dueDay, '2026-11-01');
    });

    test('tarihin kendisinde yapılırsa değişmez', () {
      // `nextSeasonalDate` zaten "sonraki"ni veriyor; K-29 tekrar atlamamalı.
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-11-01'),
      );
      expect(s.dueDay, '2027-04-01');
    });

    test('tarihten sonra yapılırsa değişmez', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-11-02'),
      );
      expect(s.dueDay, '2027-04-01');
    });

    test("kurulum günü yedeği K-29'u tetiklemez", () {
      // 25 Eki'de kurulan uygulama 1 Kas'ı "yapılmış" saymamalı.
      final ItemStatus s = status(
        item(schedule: seasonal(), startsFromInstall: true),
        today: DateTime(2026, 10, 26),
        installDay: DateTime(2026, 10, 25),
      );
      expect(s.dueDay, '2026-11-01');
    });

    test('tek tarihli maddede bir yıl sonraya geçer', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.seasonal(const <SeasonalDate>[SeasonalDate(11, 1)]),
          lastDoneDay: '2026-10-25',
        ),
      );
      expect(s.dueDay, '2027-11-01');
    });

    test('#25 son 2026-04-05, today 2026-10-20 → soon, daysLeft 12', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-04-05'),
        today: DateTime(2026, 10, 20),
      );
      expect(s.state, ItemState.soon);
      expect(s.daysLeft, 12);
      expect(s.shortText, '12 gün kaldı');
    });

    test('#26 son null, startsFromInstall → ok, vade 2026-11-01', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), startsFromInstall: true),
      );
      expect(s.state, ItemState.ok);
      expect(s.dueDay, '2026-11-01');
      expect(s.shortText, '1 Kas');
    });

    test('#27 son 2026-11-02 → ok, vade 2027-04-01, daysLeft 210', () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-11-02'),
      );
      expect(s.state, ItemState.ok);
      expect(s.dueDay, '2027-04-01');
      expect(s.daysLeft, 210);
      expect(s.shortText, '1 Nis 2027');
    });

    test('#28 son 2026-11-01 → aynı gün "sonraki" sayılmaz, vade 2027-04-01',
        () {
      final ItemStatus s = status(
        item(schedule: seasonal(), lastDoneDay: '2026-11-01'),
      );
      expect(s.state, ItemState.ok);
      expect(s.dueDay, '2027-04-01');
      expect(s.shortText, '1 Nis 2027');
    });
  });

  group('§1 sıralama (K-17)', () {
    test('gecikmişler oran sırasında: #16 önce, #17 sonra', () {
      final ItemStatus a = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2025-08-20',
          lastDoneKm: 110000,
        ),
      );
      final ItemStatus b = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-01-01',
          lastDoneKm: 103000,
        ),
      );
      expect(a.sortKey, closeTo(-14 / 365, 1e-12));
      expect(b.sortKey, closeTo(-420 / 15000, 1e-12));
      expect(a.sortKey, lessThan(b.sortKey));
    });

    test('gün ve km maddeleri aynı ölçekte sıralanıyor', () {
      final ItemStatus days = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-31'),
      );
      final ItemStatus km = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 100000),
      );
      expect(days.sortKey, closeTo(11 / 14, 1e-12));
      expect(km.sortKey, closeTo(11580 / 30000, 1e-12));
      expect(km.sortKey, lessThan(days.sortKey));
    });

    test('unknown sonsuz anahtar alıyor (şablon sırası korunur)', () {
      expect(status(item(schedule: Schedule.km(30000))).sortKey, double.infinity);
    });

    test('erteleme sortKey\'i değiştirmiyor', () {
      final CheckItem base = item(
        schedule: Schedule.days(14),
        lastDoneDay: '2026-08-12',
      );
      final ItemStatus plain = status(base);
      final ItemStatus snoozed = status(
        base.copyWith(snoozeUntilDay: '2026-09-04'),
      );
      expect(snoozed.sortKey, plain.sortKey);
      expect(snoozed.state, ItemState.soon);
      expect(plain.state, ItemState.overdue);
    });

    test('K-22 proximityKey: gün maddesinde kalan gün', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-31'),
      );
      expect(s.proximityKey, 11);
    });

    test('K-22 proximityKey: km maddesi güne çevriliyor', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 100000),
      );
      expect(s.kmLeft, 11580);
      expect(s.proximityKey, closeTo(11580 / 50, 1e-9));
    });

    test('K-22 proximityKey: both maddede bağlayıcı boyut belirliyor', () {
      final ItemStatus kmBinds = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-03-12',
          lastDoneKm: 104900,
        ),
      );
      expect(kmBinds.binding, BindingDim.km);
      expect(kmBinds.proximityKey, closeTo(1480 / 50, 1e-9));

      final ItemStatus daysBind = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2025-09-10',
          lastDoneKm: 110000,
        ),
      );
      expect(daysBind.binding, BindingDim.days);
      expect(daysBind.proximityKey, 7);
    });

    test('K-22 proximityKey: unknown sonsuz', () {
      expect(
        status(item(schedule: Schedule.km(30000))).proximityKey,
        double.infinity,
      );
    });

    test('mevsimselde bölen 365', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.seasonal(kSeasonalDates),
          lastDoneDay: '2026-04-05',
        ),
      );
      expect(s.sortKey, closeTo(59 / 365, 1e-12));
    });
  });

  group('sınır durumları', () {
    test('gece yarısına yakın saat sonucu değiştirmiyor', () {
      final CheckItem i = item(
        schedule: Schedule.days(14),
        lastDoneDay: '2026-08-12',
      );
      final ItemStatus a = status(i, today: DateTime(2026, 9, 3, 0, 1));
      final ItemStatus b = status(i, today: DateTime(2026, 9, 3, 23, 59));
      expect(a.daysLeft, b.daysLeft);
      expect(a.shortText, b.shortText);
    });

    test('km eşiğinin bir fazlası ok', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 89421),
      );
      expect(s.state, ItemState.ok);
      expect(s.kmLeft, 1001);
    });

    test('gün eşiğinin bir fazlası ok', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(14), lastDoneDay: '2026-08-24'),
      );
      expect(s.daysLeft, 4);
      expect(s.state, ItemState.ok);
    });

    test('mevsimsel eşiğinin bir fazlası ok', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.seasonal(kSeasonalDates),
          lastDoneDay: '2026-04-05',
        ),
        today: DateTime(2026, 10, 17),
      );
      expect(s.daysLeft, 15);
      expect(s.state, ItemState.ok);
    });

    test('kmLeft tam 0 → soon, "0 km kaldı"', () {
      final ItemStatus s = status(
        item(schedule: Schedule.km(30000), lastDoneKm: 88420),
      );
      expect(s.kmLeft, 0);
      expect(s.state, ItemState.soon);
      expect(s.shortText, '0 km kaldı');
    });

    test('both: yalnız gün yarısı doluysa unknown', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-03-12',
        ),
      );
      expect(s.state, ItemState.unknown);
    });

    test('both: yalnız km yarısı doluysa unknown', () {
      final ItemStatus s = status(
        item(
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneKm: 104900,
        ),
      );
      expect(s.state, ItemState.unknown);
    });

    test('artık yıl 29 Şubat üzerinden geçiyor', () {
      final ItemStatus s = status(
        item(schedule: Schedule.days(365), lastDoneDay: '2027-09-16'),
        today: DateTime(2028, 3, 1),
      );
      expect(s.dueDay, '2028-09-15');
    });

    test('nextSeasonalDate tek tarihte yılı ilerletiyor', () {
      expect(
        nextSeasonalDate(
          <SeasonalDate>[const SeasonalDate(11, 1)],
          DateTime(2026, 11, 1),
        ),
        DateTime(2027, 11, 1),
      );
      expect(
        nextSeasonalDate(
          <SeasonalDate>[const SeasonalDate(11, 1)],
          DateTime(2026, 10, 31),
        ),
        DateTime(2026, 11, 1),
      );
    });

    test('nextSeasonalDate yıl sonunu geçiyor', () {
      expect(
        nextSeasonalDate(kSeasonalDates, DateTime(2026, 12, 31)),
        DateTime(2027, 4, 1),
      );
    });
  });
}
