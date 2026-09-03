import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/format_tr.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/domain/item_grouping.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/features/km_entry/km_entry_sheet.dart';
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

  Future<int> seedVehicle({int km = 118420}) async {
    final int id = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea'),
        currentKm: km,
        btName: const Value<String?>('Uconnect'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(id, seed);
    return id;
  }

  Future<void> keepOnly(int vehicleId, Set<String> keys) async {
    for (final CheckItemRow r in await db.itemDao.getAll(vehicleId)) {
      await db.itemDao.setEnabled(r.id, keys.contains(r.templateKey));
    }
  }

  // ------------------------------------------------------------- doğrulama

  group('validateKmEntry', () {
    test('boş ve geçersiz giriş reddediliyor', () {
      expect(validateKmEntry('', 118420), S.errKmRequired);
      expect(validateKmEntry('abc', 118420), S.errKmRequired);
    });

    test('küçük değer reddediliyor, metin doğru', () {
      expect(
        validateKmEntry('118419', 118420),
        'Şu anki km 118.420. Daha küçük olamaz',
      );
      expect(validateKmEntry('0', 118420), kmTooSmallText(118420));
    });

    test('eşit değer kabul', () {
      expect(validateKmEntry('118420', 118420), isNull);
    });

    test('büyük değer kabul', () {
      expect(validateKmEntry('119950', 118420), isNull);
    });

    test('binlik noktalı giriş kabul', () {
      expect(validateKmEntry('119.950', 118420), isNull);
    });
  });

  test('kmUpdatedText', () {
    expect(kmUpdatedText(119950), 'Km güncellendi: 119.950');
  });

  // --------------------------------------------------------------- widget

  group('km giriş alt sayfası', () {
    Future<void> pumpAndOpen(WidgetTester tester) async {
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
      await tester.tap(find.byKey(const Key('home_km_entry')));
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

    testWidgets('açılışta güncel km dolu geliyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      await pumpAndOpen(tester);

      expect(find.byKey(const Key('km_entry_title')), findsOneWidget);
      final TextField field = tester.widget<TextField>(
        find.byKey(const Key('km_entry_field')),
      );
      expect(field.controller!.text, '118420');
      // Metin seçili gelmeli: yazmaya başlayınca üzerine yazılsın.
      expect(field.controller!.selection.baseOffset, 0);
      expect(field.controller!.selection.extentOffset, '118420'.length);
      await disposeTree(tester);
    });

    testWidgets('küçük değer reddediliyor, sayfa kapanmıyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await pumpAndOpen(tester);

      await tester.enterText(
        find.byKey(const Key('km_entry_field')),
        '100000',
      );
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();

      expect(find.text('Şu anki km 118.420. Daha küçük olamaz'), findsOneWidget);
      expect(find.byKey(const Key('km_entry_title')), findsOneWidget);
      expect((await db.vehicleDao.get())!.currentKm, 118420);
      expect(v, isNotNull);

      await flushToast(tester);
      await disposeTree(tester);
    });

    testWidgets('boş değer reddediliyor', (WidgetTester tester) async {
      await seedVehicle();
      await pumpAndOpen(tester);

      await tester.enterText(find.byKey(const Key('km_entry_field')), '');
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();

      // "Km gir" hem başlıktaki bağlantı hem de bu uyarı; spec ikisini de
      // böyle yazıyor (§3.2 ve §3.5). Uyarıyı SnackBar içinde arıyoruz.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(S.errKmRequired),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('km_entry_title')), findsOneWidget);

      await flushToast(tester);
      await disposeTree(tester);
    });

    testWidgets('eşit değer kabul ediliyor', (WidgetTester tester) async {
      await seedVehicle();
      await pumpAndOpen(tester);

      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('km_entry_title')), findsNothing);
      expect((await db.vehicleDao.get())!.currentKm, 118420);

      await flushToast(tester);
      await disposeTree(tester);
    });

    testWidgets('büyük değer kaydediliyor, toast ve başlık güncelleniyor', (
      WidgetTester tester,
    ) async {
      await seedVehicle();
      await pumpAndOpen(tester);

      await tester.enterText(
        find.byKey(const Key('km_entry_field')),
        '119950',
      );
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('km_entry_title')), findsNothing);
      expect(find.text('Km güncellendi: 119.950'), findsOneWidget);
      expect((await db.vehicleDao.get())!.currentKm, 119950);
      // Ana ekran başlığı da değişti.
      expect(find.text('119.950 km'), findsOneWidget);

      await flushToast(tester);
      await disposeTree(tester);
    });

    testWidgets('km bazlı maddelerin durumu anında güncelleniyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await keepOnly(v, <String>{'air_filter'});
      // 30.000 km aralık, son 100.000 → vade 130.000.
      final CheckItemRow air = (await db.itemDao.getAll(v)).firstWhere(
        (CheckItemRow r) => r.templateKey == 'air_filter',
      );
      await db.itemDao.setLastDone(air.id, day: '2026-03-12', km: 100000);

      await pumpAndOpen(tester);
      // Açmadan önceki hâl: 130.000 − 118.420 = 11.580 km kaldı.
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();
      await flushToast(tester);
      expect(find.text('11.580 km kaldı'), findsOneWidget);

      // 129.500'e çıkınca 500 km kalır → yaklaşan.
      await tester.tap(find.byKey(const Key('home_km_entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('km_entry_field')),
        '129500',
      );
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();
      await flushToast(tester);

      expect(find.text('500 km kaldı'), findsOneWidget);
      expect(find.byKey(const Key('section_soon')), findsOneWidget);
      expect(find.byKey(const Key('section_ok')), findsNothing);

      await disposeTree(tester);
    });

    testWidgets('km artınca gecikmiş bölümüne düşüyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await keepOnly(v, <String>{'air_filter'});
      final CheckItemRow air = (await db.itemDao.getAll(v)).firstWhere(
        (CheckItemRow r) => r.templateKey == 'air_filter',
      );
      await db.itemDao.setLastDone(air.id, day: '2026-03-12', km: 100000);

      await pumpAndOpen(tester);
      await tester.enterText(
        find.byKey(const Key('km_entry_field')),
        '130500',
      );
      await tester.tap(find.byKey(const Key('km_entry_save')));
      await tester.pumpAndSettle();
      await flushToast(tester);

      expect(find.byKey(const Key('section_overdue')), findsOneWidget);
      expect(find.text('500 km geçti'), findsOneWidget);

      await disposeTree(tester);
    });
  });

  // ----------------------------------------------------- sağlayıcı akışı

  test('km değişimi statusesProvider üzerinden yayılıyor', () async {
    final int v = await seedVehicle();
    await keepOnly(v, <String>{'air_filter'});
    final CheckItemRow air = (await db.itemDao.getAll(v)).firstWhere(
      (CheckItemRow r) => r.templateKey == 'air_filter',
    );
    await db.itemDao.setLastDone(air.id, day: '2026-03-12', km: 100000);

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(db),
        seedProvider.overrideWithValue(seed),
        platformBridgeProvider.overrideWithValue(FakeBridge()),
        todayProvider.overrideWith((Ref ref) => today),
        installDayProvider.overrideWith((Ref ref) => installDay),
      ],
    );
    addTearDown(c.dispose);
    c.listen(statusesProvider, (_, _) {}, fireImmediately: true);
    await c.read(vehicleProvider.future);
    await c.read(itemsProvider.future);

    ItemStatus statusOf() => c
        .read(statusesProvider)
        .firstWhere((StatusedItem e) => e.item.id == air.id)
        .status;

    expect(statusOf().kmLeft, 11580);
    expect(statusOf().state, ItemState.ok);

    await c.read(vehicleRepoProvider).setCurrentKm(v, 129500);
    await c.read(vehicleProvider.future);
    // Araç akışı yayılana kadar bekle.
    for (int i = 0; i < 10 && statusOf().kmLeft != 500; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(statusOf().kmLeft, 500);
    expect(statusOf().state, ItemState.soon);
  });
}
