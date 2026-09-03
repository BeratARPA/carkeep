import 'package:carkeep/core/constants.dart';
import 'package:carkeep/data/db/daos/settings_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/platform/platform_bridge.dart';
import 'package:carkeep/data/repositories/trip_repo.dart';
import 'package:carkeep/domain/models/trip.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 01-spec §7.3: Kotlin olaylarının `trips` / `settings`'e işlenmesi.
void main() {
  late AppDatabase db;
  late TripRepo repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TripRepo(db);
    addTearDown(db.close);
  });

  TripEvent trip({
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    int durationMin = 25,
    bool counted = true,
    bool notified = true,
    int overdueCount = 2,
    String? note = kTripNoteOk,
  }) => TripEvent(
    connectedAt: connectedAt ?? DateTime(2026, 9, 3, 14, 5),
    disconnectedAt: disconnectedAt ?? DateTime(2026, 9, 3, 14, 30),
    durationMin: durationMin,
    counted: counted,
    notified: notified,
    overdueCount: overdueCount,
    note: note,
  );

  group('applyPendingEvents', () {
    test('boş liste hiçbir şey yazmıyor', () async {
      expect(await repo.applyPendingEvents(const <PendingEvent>[]), 0);
      expect(await repo.getAll(), isEmpty);
    });

    test('sürüş olayı bütün alanlarıyla yazılıyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[trip()]);

      final Trip row = (await repo.getAll()).single;
      expect(row.connectedAt, DateTime(2026, 9, 3, 14, 5));
      expect(row.disconnectedAt, DateTime(2026, 9, 3, 14, 30));
      expect(row.durationMin, 25);
      expect(row.counted, isTrue);
      expect(row.notified, isTrue);
      expect(row.overdueCount, 2);
      expect(row.note, kTripNoteOk);
      expect(row.isFallback, isFalse);
    });

    test('bağlanma anı bilinmeyen sürüş null yazılıyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[
        trip(note: kTripNoteShortTrip, counted: false, notified: false)
            .copyForTest(),
      ]);
      expect((await repo.getAll()).single.connectedAt, isNull);
    });

    test('erteleme ayarlara yazılıyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[
        const SnoozeEvent(untilDay: '2026-09-04'),
      ]);

      expect(
        await db.settingsDao.get(SettingKeys.globalSnoozeUntilDay),
        '2026-09-04',
      );
      expect(await repo.getAll(), isEmpty);
    });

    test('boş erteleme günü ayarı temizliyor', () async {
      await db.settingsDao.set(SettingKeys.globalSnoozeUntilDay, '2026-09-04');
      await repo.applyPendingEvents(<PendingEvent>[
        const SnoozeEvent(untilDay: ''),
      ]);
      expect(
        await db.settingsDao.get(SettingKeys.globalSnoozeUntilDay),
        isNull,
      );
    });

    test('K-26: yedek bildirim trips\'e yazılıyor ama sürüş değil', () async {
      await repo.applyPendingEvents(<PendingEvent>[
        FallbackEvent(at: DateTime(2026, 9, 10, 19), overdueCount: 3),
      ]);

      final Trip row = (await repo.getAll()).single;
      expect(row.note, kTripNoteFallback);
      expect(row.isFallback, isTrue);
      expect(row.connectedAt, isNull);
      expect(row.durationMin, 0);
      expect(row.counted, isFalse);
      expect(row.notified, isTrue);
      expect(row.overdueCount, 3);

      // Tanı satırı "Son kopma:" der; yedek bildirim kopma değil.
      expect(await repo.lastTrip(), isNull);
    });

    test('yedek satırı gerçek sürüşü tanı satırından düşürmüyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[
        trip(disconnectedAt: DateTime(2026, 9, 3, 14, 30)),
        FallbackEvent(at: DateTime(2026, 9, 10, 19), overdueCount: 1),
      ]);

      expect((await repo.getAll()).length, 2);
      // Yedek daha yeni ama tanı satırı yine kopmayı gösteriyor.
      expect((await repo.lastTrip())!.disconnectedAt, DateTime(2026, 9, 3, 14, 30));
    });

    test('notu olmayan satır tanı satırına giriyor', () async {
      // `note IS NULL` SQL'de `note = "fallback"` ile NULL döner; filtre
      // bunu elememeli.
      await repo.applyPendingEvents(<PendingEvent>[trip(note: null)]);
      expect(await repo.lastTrip(), isNotNull);
    });

    test('karışık olaylar sırayla işleniyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[
        trip(disconnectedAt: DateTime(2026, 9, 3, 8), note: kTripNoteOk),
        const SnoozeEvent(untilDay: '2026-09-04'),
        trip(
          disconnectedAt: DateTime(2026, 9, 3, 18),
          note: kTripNoteOncePerDay,
          notified: false,
        ),
      ]);

      expect((await repo.getAll()).length, 2);
      expect((await repo.lastTrip())!.note, kTripNoteOncePerDay);
      expect(
        await db.settingsDao.get(SettingKeys.globalSnoozeUntilDay),
        '2026-09-04',
      );
    });

    test('ikinci kez boş liste gelince tekrar eklemiyor', () async {
      await repo.applyPendingEvents(<PendingEvent>[trip()]);
      await repo.applyPendingEvents(const <PendingEvent>[]);
      expect((await repo.getAll()).length, 1);
    });
  });

  group('watchLastTrip', () {
    test('en yeni kopmayı yayınlıyor', () async {
      final Stream<Trip?> stream = repo.watchLastTrip();
      expect(await stream.first, isNull);

      await repo.applyPendingEvents(<PendingEvent>[
        trip(disconnectedAt: DateTime(2026, 9, 1, 10)),
        trip(disconnectedAt: DateTime(2026, 9, 3, 10)),
      ]);

      expect((await repo.watchLastTrip().first)!.disconnectedAt,
          DateTime(2026, 9, 3, 10));
    });
  });
}

/// `connectedAt` null olan bir sürüş olayı (kopma öncesi bağlanma görülmemiş).
extension on TripEvent {
  TripEvent copyForTest() => TripEvent(
    connectedAt: null,
    disconnectedAt: disconnectedAt,
    durationMin: 0,
    counted: counted,
    notified: notified,
    overdueCount: overdueCount,
    note: note,
  );
}
