import 'package:carkeep/domain/item_grouping.dart';
import 'package:carkeep/domain/models/check_item.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/domain/models/schedule.dart';
import 'package:carkeep/domain/status_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'status_calculator_test.dart'
    show item, kCurrentKm, kInstallDay, kSeasonalDates, kToday;

StatusedItem s(CheckItem i) => (
  item: i,
  status: StatusCalculator.compute(
    item: i,
    currentKm: kCurrentKm,
    installDay: kInstallDay,
    today: kToday,
  ),
);

void main() {
  test('bölümler doğru dolduruluyor', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      // overdue
      s(item(id: 1, schedule: Schedule.days(14), lastDoneDay: '2026-08-12')),
      // soon
      s(item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-21')),
      // ok
      s(item(id: 3, schedule: Schedule.days(14), lastDoneDay: '2026-08-31')),
      // unknown
      s(item(id: 4, schedule: Schedule.km(30000))),
    ]);
    expect(g.overdue.length, 1);
    expect(g.soon.length, 1);
    expect(g.ok.length, 1);
    expect(g.unknown.length, 1);
    expect(g.total, 4);
    expect(g.nothingPending, isFalse);
  });

  test('kapalı madde hiçbir bölüme girmiyor', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(
        item(
          id: 1,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          enabled: false,
        ),
      ),
      s(item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-31')),
    ]);
    expect(g.total, 1);
    expect(g.overdue, isEmpty);
    expect(g.ok.single.item.id, 2);
  });

  test('gecikmiş: en çok gecikmiş önce (06 §1 sıralama örneği)', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      // #17: km bağlayıcı, oran -0,028
      s(
        item(
          id: 17,
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2026-01-01',
          lastDoneKm: 103000,
        ),
      ),
      // #16: gün bağlayıcı, oran -0,038
      s(
        item(
          id: 16,
          schedule: Schedule.both(days: 365, km: 15000),
          lastDoneDay: '2025-08-20',
          lastDoneKm: 110000,
        ),
      ),
    ]);
    expect(
      g.overdue.map((StatusedItem e) => e.item.id).toList(),
      <int>[16, 17],
    );
  });

  test('yaklaşan: en yakın önce (K-22), gün ve km karışık', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      // kmLeft 1000 → 1000/50 = 20 gün
      s(item(id: 1, schedule: Schedule.km(30000), lastDoneKm: 89420)),
      // daysLeft 0
      s(item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-20')),
      // daysLeft 1
      s(item(id: 3, schedule: Schedule.days(30), lastDoneDay: '2026-08-05')),
    ]);
    expect(
      g.soon.map((StatusedItem e) => e.item.id).toList(),
      <int>[2, 3, 1],
    );
    for (int i = 1; i < g.soon.length; i++) {
      expect(
        g.soon[i - 1].status.proximityKey <= g.soon[i].status.proximityKey,
        isTrue,
      );
    }
  });

  test('zamanında: takvimde yakın olan önce (K-22)', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      // kmLeft 11.580 → 231,6 gün
      s(item(id: 1, schedule: Schedule.km(30000), lastDoneKm: 100000)),
      // daysLeft 11
      s(item(id: 2, schedule: Schedule.days(14), lastDoneDay: '2026-08-31')),
    ]);
    expect(g.ok.map((StatusedItem e) => e.item.id).toList(), <int>[2, 1]);
  });

  test('K-22: seyrek aralıklı uzak madde, sık aralıklı yakın maddenin '
      'üstüne çıkmıyor', () {
    // Cihazda görülen durum: mevsimsel 59 gün (oran 0,162) ile
    // 14 günlük madde 14 gün (oran 1,0). Oranla mevsimsel öne geçiyordu.
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(
        item(
          id: 1,
          sortOrder: 33,
          schedule: Schedule.seasonal(kSeasonalDates),
          startsFromInstall: true,
        ),
      ),
      s(
        item(
          id: 2,
          sortOrder: 0,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-20',
          startsFromInstall: true,
        ),
      ),
    ]);
    // 14 günlük madde 2026-09-03'te vade → soon; mevsimsel 59 gün → ok.
    expect(g.ok.single.item.id, 1);
    expect(g.soon.single.item.id, 2);

    // Aynı bölümde olsalardı da yakın olan önde olurdu:
    final GroupedItems g2 = groupForHome(<StatusedItem>[
      s(
        item(
          id: 1,
          sortOrder: 33,
          schedule: Schedule.seasonal(kSeasonalDates),
          startsFromInstall: true,
        ),
      ),
      s(
        item(
          id: 2,
          sortOrder: 0,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-31',
        ),
      ),
    ]);
    expect(g2.ok.map((StatusedItem e) => e.item.id).toList(), <int>[2, 1]);
  });

  test('bilinmiyor: şablon sırası korunuyor', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(item(id: 3, sortOrder: 20, schedule: Schedule.km(30000))),
      s(item(id: 1, sortOrder: 5, schedule: Schedule.km(30000))),
      s(item(id: 2, sortOrder: 12, schedule: Schedule.km(30000))),
    ]);
    expect(
      g.unknown.map((StatusedItem e) => e.item.id).toList(),
      <int>[1, 2, 3],
    );
  });

  test('eşit sortKey\'de şablon sırası bozulmuyor (kararlı)', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(
        item(
          id: 9,
          sortOrder: 9,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-31',
        ),
      ),
      s(
        item(
          id: 2,
          sortOrder: 2,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-31',
        ),
      ),
    ]);
    expect(g.ok.map((StatusedItem e) => e.item.id).toList(), <int>[2, 9]);
  });

  test('gecikmiş ve yaklaşan boşsa nothingPending', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(item(id: 1, schedule: Schedule.days(14), lastDoneDay: '2026-08-31')),
      s(item(id: 2, schedule: Schedule.km(30000))),
    ]);
    expect(g.nothingPending, isTrue);
  });

  test('ertelenmiş gecikmiş madde yaklaşan bölümünde ve başta', () {
    final GroupedItems g = groupForHome(<StatusedItem>[
      s(item(id: 1, schedule: Schedule.days(14), lastDoneDay: '2026-08-21')),
      s(
        item(
          id: 2,
          schedule: Schedule.days(14),
          lastDoneDay: '2026-08-12',
          snoozeUntilDay: '2026-09-04',
        ),
      ),
    ]);
    expect(g.overdue, isEmpty);
    expect(g.soon.map((StatusedItem e) => e.item.id).toList(), <int>[2, 1]);
    expect(g.soon.first.status.shortText, 'Yarın');
    expect(g.soon.first.status.state, ItemState.soon);
  });

  test('boş girdi', () {
    final GroupedItems g = groupForHome(const <StatusedItem>[]);
    expect(g.total, 0);
    expect(g.nothingPending, isTrue);
  });
}
