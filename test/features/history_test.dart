import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/daos/log_dao.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/models/check_log.dart';
import 'package:carkeep/features/history/history_screen.dart';
import 'package:carkeep/providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'setup_test.dart' show FakeBridge;

void main() {
  late Seed seed;

  setUpAll(() {
    seed = SeedLoader.parse(
      File('assets/seed/checklist_seed.json').readAsStringSync(),
    );
  });

  late AppDatabase db;
  final DateTime today = DateTime(2026, 9, 3);
  final DateTime installDay = DateTime(2026, 8, 20);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  Future<int> seedVehicle() async {
    final int id = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea'),
        currentKm: 118420,
        btName: const Value<String?>('Uconnect'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(id, seed);
    return id;
  }

  Future<int> itemId(int vehicleId, String templateKey) async =>
      (await db.itemDao.getAll(vehicleId))
          .firstWhere((CheckItemRow r) => r.templateKey == templateKey)
          .id;

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(
            FakeBridge(bluetooth: true, notification: true, battery: true),
          ),
          todayProvider.overrideWith((Ref ref) => today),
          installDayProvider.overrideWith((Ref ref) => installDay),
        ],
        child: const CarKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.tabHistory));
    await tester.pumpAndSettle();
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> flushToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  // ------------------------------------------------------------- alt metin

  group('satır alt metni', () {
    CheckLog log({
      int? km = 118100,
      String? value,
      String? note,
      String kind = kLogKindDone,
    }) => CheckLog(
      id: 1,
      itemId: 2,
      doneAt: DateTime(2026, 8, 16, 10),
      doneDay: '2026-08-16',
      km: km,
      value: value,
      note: note,
      kind: kind,
    );

    test('değer, km ve not', () {
      expect(
        historyLogSubtitle(
          log(value: '2,3 / 2,3 / 2,3 / 2,2 bar', note: 'Arka sağ düşük'),
        ),
        '2,3 / 2,3 / 2,3 / 2,2 bar, 118.100 km. Arka sağ düşük',
      );
    });

    test('yalnız km', () {
      expect(historyLogSubtitle(log()), '118.100 km');
    });

    test('düzeltme etiketleniyor (K-23)', () {
      expect(
        historyLogSubtitle(log(km: null, kind: kLogKindFix)),
        S.logKindFix,
      );
    });

    test('yalnız not', () {
      expect(historyLogSubtitle(log(km: null, note: 'Sadece not')), 'Sadece not');
    });
  });

  // --------------------------------------------------------------- ekran

  testWidgets('kayıt yokken boş durum metni', (WidgetTester tester) async {
    await seedVehicle();
    await pumpHistory(tester);

    expect(find.byKey(const Key('history_empty')), findsOneWidget);
    expect(find.text(S.historyEmpty), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('kayıtlar güne göre gruplu, yeni üstte', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int oil = await itemId(v, 'oil_level');
    final int tire = await itemId(v, 'tire_pressure');

    await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 8, 12, 10),
      doneDay: '2026-08-12',
      km: 117900,
      value: 'Orta',
    );
    await db.logDao.addLog(
      itemId: tire,
      doneAt: DateTime(2026, 9, 3, 9),
      doneDay: '2026-09-03',
      km: 118420,
      value: '2,3 / 2,3 / 2,3 / 2,2 bar',
      note: 'Arka sağ düşük',
    );
    await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
      value: 'Orta',
    );

    await pumpHistory(tester);

    expect(find.byKey(const Key('day_2026-09-03')), findsOneWidget);
    expect(find.byKey(const Key('day_2026-08-12')), findsOneWidget);
    expect(find.text('3 Eyl 2026'), findsOneWidget);
    expect(find.text('12 Ağu 2026'), findsOneWidget);

    // Yeni gün üstte.
    final Offset newer = tester.getTopLeft(
      find.byKey(const Key('day_2026-09-03')),
    );
    final Offset older = tester.getTopLeft(
      find.byKey(const Key('day_2026-08-12')),
    );
    expect(newer.dy, lessThan(older.dy));

    expect(
      find.text('2,3 / 2,3 / 2,3 / 2,2 bar, 118.420 km. Arka sağ düşük'),
      findsOneWidget,
    );
    await disposeTree(tester);
  });

  testWidgets('kayıt detayı açılıyor', (WidgetTester tester) async {
    final int v = await seedVehicle();
    final int oil = await itemId(v, 'oil_level');
    final int logId = await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
      value: 'Orta',
      note: 'Yarım litre',
    );

    await pumpHistory(tester);
    await tester.tap(find.byKey(Key('log_$logId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('log_sheet_title')), findsOneWidget);
    expect(find.text('Motor yağı seviyesi'), findsWidgets);
    expect(find.text('118.420 km'), findsOneWidget);
    expect(find.text('Yarım litre'), findsOneWidget);
    expect(find.byKey(const Key('log_delete')), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('silme onayı iptal edilince hiçbir şey olmuyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int oil = await itemId(v, 'oil_level');
    final int logId = await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
      value: 'Orta',
    );

    await pumpHistory(tester);
    await tester.tap(find.byKey(Key('log_$logId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_delete')));
    await tester.pumpAndSettle();

    expect(find.text(S.historyDeleteConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete_cancel')));
    await tester.pumpAndSettle();

    expect((await db.logDao.getAll()).length, 1);
    expect((await db.itemDao.getById(oil))!.lastDoneDay, '2026-09-03');
    // Alt sayfa hâlâ açık.
    expect(find.byKey(const Key('log_sheet_title')), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('silme onaylanınca kayıt gidiyor ve madde durumu değişiyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int oil = await itemId(v, 'oil_level');
    await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 8, 12, 10),
      doneDay: '2026-08-12',
      km: 117900,
      value: 'Orta',
    );
    final int newerLog = await db.logDao.addLog(
      itemId: oil,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
      value: "Max'a yakın",
    );
    expect((await db.itemDao.getById(oil))!.lastDoneDay, '2026-09-03');

    await pumpHistory(tester);
    await tester.tap(find.byKey(Key('log_$newerLog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm')));
    await tester.pumpAndSettle();

    expect(find.text(S.historyDeleted), findsOneWidget);
    expect((await db.logDao.getAll()).length, 1);

    // Madde bir önceki kayda döndü.
    final CheckItemRow row = (await db.itemDao.getById(oil))!;
    expect(row.lastDoneDay, '2026-08-12');
    expect(row.lastDoneKm, 117900);
    expect(row.lastValue, 'Orta');

    // Liste de güncellendi.
    expect(find.byKey(Key('log_$newerLog')), findsNothing);

    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('tek kayıt silinince madde Bilinmiyor\'a dönüyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int air = await itemId(v, 'air_filter');
    final int only = await db.logDao.addLog(
      itemId: air,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2026-09-03',
      km: 118420,
    );

    await pumpHistory(tester);
    await tester.tap(find.byKey(Key('log_$only')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm')));
    await tester.pumpAndSettle();

    final CheckItemRow row = (await db.itemDao.getById(air))!;
    expect(row.lastDoneDay, isNull);
    expect(row.lastDoneKm, isNull);
    expect(find.byKey(const Key('history_empty')), findsOneWidget);

    await flushToast(tester);
    await disposeTree(tester);
  });

  testWidgets('K-23: düzeltme satırı geçmişte görünüyor ve silinebiliyor', (
    WidgetTester tester,
  ) async {
    final int v = await seedVehicle();
    final int belt = await itemId(v, 'timing_belt');
    final int fixLog = await db.logDao.addLog(
      itemId: belt,
      doneAt: DateTime(2026, 9, 3, 10),
      doneDay: '2022-05-10',
      km: 60000,
      kind: kLogKindFix,
    );

    await pumpHistory(tester);
    expect(find.textContaining(S.logKindFix), findsOneWidget);

    await tester.tap(find.byKey(Key('log_$fixLog')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log_delete')), findsOneWidget);
    await disposeTree(tester);
  });
}
