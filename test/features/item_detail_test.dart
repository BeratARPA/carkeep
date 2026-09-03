import 'dart:io';

import 'package:carkeep/app.dart';
import 'package:carkeep/core/strings_tr.dart';
import 'package:carkeep/data/db/database.dart';
import 'package:carkeep/data/repositories/item_repo.dart';
import 'package:carkeep/data/seed/seed_loader.dart';
import 'package:carkeep/data/repositories/item_list_repo.dart';
import 'package:carkeep/domain/models/check_item.dart';
import 'package:carkeep/domain/models/check_log.dart';
import 'package:carkeep/domain/models/item_status.dart';
import 'package:carkeep/domain/models/measure.dart';
import 'package:carkeep/features/item_detail/item_detail_controller.dart';
import 'package:carkeep/features/item_detail/item_detail_sheet.dart';
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

  Future<int> seedVehicle({double? front, double? rear}) async {
    final int vehicleId = await db.vehicleDao.insertVehicle(
      VehiclesCompanion.insert(
        brand: 'Fiat',
        model: const Value<String>('Egea'),
        currentKm: 118420,
        btName: const Value<String?>('Uconnect'),
        btAddress: const Value<String?>('12:34:56:78:9A:BC'),
        tireFrontBar: Value<double?>(front),
        tireRearBar: Value<double?>(rear),
        createdAt: DateTime(2026, 8, 20),
      ),
    );
    await ItemRepo(db).installSeed(vehicleId, seed);
    return vehicleId;
  }

  Future<int> itemId(int vehicleId, String templateKey) async {
    return (await db.itemDao.getAll(vehicleId))
        .firstWhere((CheckItemRow r) => r.templateKey == templateKey)
        .id;
  }

  Future<void> keepOnly(int vehicleId, Set<String> keys) async {
    for (final CheckItemRow r in await db.itemDao.getAll(vehicleId)) {
      await db.itemDao.setEnabled(r.id, keys.contains(r.templateKey));
    }
  }

  ProviderContainer makeContainer() {
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
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    await c.read(vehicleProvider.future);
    await c.read(itemsProvider.future);
  }

  // ------------------------------------------------------------- doğrulama

  group('ölçüm doğrulaması', () {
    test('level zorunlu', () {
      final Measure m = Measure.level(<String>['Min', 'Orta', 'Max']);
      expect(validateMeasure(m, const MeasureInput()), S.errPickLevel);
      expect(
        validateMeasure(m, const MeasureInput(level: 'Orta')),
        isNull,
      );
    });

    test('tires dördü de zorunlu', () {
      const Measure m = Measure.tires();
      expect(validateMeasure(m, const MeasureInput()), S.errAllFourTires);
      expect(
        validateMeasure(
          m,
          const MeasureInput(tires: <String>['2,3', '2,3', '2,3', '']),
        ),
        S.errAllFourTires,
      );
      expect(
        validateMeasure(
          m,
          const MeasureInput(tires: <String>['2,3', '2.3', '2,2', '2,4']),
        ),
        isNull,
      );
    });

    test('number ve none isteğe bağlı', () {
      expect(
        validateMeasure(
          const Measure.number(unit: 'mm', label: 'Diş'),
          const MeasureInput(),
        ),
        isNull,
      );
      expect(
        validateMeasure(const Measure.none(), const MeasureInput()),
        isNull,
      );
    });
  });

  group('ölçüm değeri biçimi', () {
    test('tires: virgül ve nokta girişi aynı sonucu veriyor', () {
      expect(
        buildMeasureValue(
          const Measure.tires(),
          const MeasureInput(tires: <String>['2,3', '2,3', '2,3', '2,2']),
        ),
        '2,3 / 2,3 / 2,3 / 2,2 bar',
      );
      expect(
        buildMeasureValue(
          const Measure.tires(),
          const MeasureInput(tires: <String>['2.3', '2.3', '2.3', '2.2']),
        ),
        '2,3 / 2,3 / 2,3 / 2,2 bar',
      );
    });

    test('level seçilen çipi saklıyor', () {
      expect(
        buildMeasureValue(
          Measure.level(<String>['Orta']),
          const MeasureInput(level: 'Orta'),
        ),
        'Orta',
      );
    });

    test('number birimle saklanıyor', () {
      expect(
        buildMeasureValue(
          const Measure.number(unit: 'mm', label: 'Diş'),
          const MeasureInput(number: '6'),
        ),
        '6 mm',
      );
      expect(
        buildMeasureValue(
          const Measure.number(unit: 'mm', label: 'Diş'),
          const MeasureInput(number: '6,5'),
        ),
        '6,5 mm',
      );
    });

    test('none null', () {
      expect(
        buildMeasureValue(const Measure.none(), const MeasureInput()),
        isNull,
      );
    });
  });

  group('hedef basınç sapması', () {
    test('0,3 bar ve üzeri sapma vurgulanıyor', () {
      expect(tireDeviates('2,3', 2.3), isFalse);
      expect(tireDeviates('2,1', 2.3), isFalse);
      expect(tireDeviates('2,0', 2.3), isTrue);
      expect(tireDeviates('2,6', 2.3), isTrue);
    });

    test('hedef yoksa vurgu yok', () {
      expect(tireDeviates('1,0', null), isFalse);
    });

    test('boş veya geçersiz girişte vurgu yok', () {
      expect(tireDeviates('', 2.3), isFalse);
      expect(tireDeviates('abc', 2.3), isFalse);
    });

    test('hedef metni', () {
      expect(tireTargetText(front: 2.3, rear: 2.3), 'Hedef: ön 2,3 / arka 2,3');
      expect(tireTargetText(front: 2.3), 'Hedef: ön 2,3');
      expect(tireTargetText(), isNull);
    });

    test('ilk iki alan ön, son iki alan arka', () {
      expect(tireTargetFor(0, front: 2.3, rear: 2.5), 2.3);
      expect(tireTargetFor(1, front: 2.3, rear: 2.5), 2.3);
      expect(tireTargetFor(2, front: 2.3, rear: 2.5), 2.5);
      expect(tireTargetFor(3, front: 2.3, rear: 2.5), 2.5);
    });
  });

  // -------------------------------------------------------------- kaydetme

  group('Yaptım olarak kaydet', () {
    test('zorunlu ölçüm eksikken kaydetmiyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'oil_level');
      final SaveOutcome out = await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(),
          );

      expect(out, isA<SaveInvalid>());
      expect((out as SaveInvalid).message, S.errPickLevel);
      expect(await db.logDao.getAll(), isEmpty);
    });

    test('kayıt: log satırı, last_*, erteleme temizliği, toast', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'oil_level');
      await db.itemDao.setSnooze(id, '2026-09-04');

      final SaveOutcome out = await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(level: 'Orta', note: 'Yarım litre'),
          );

      expect(out, isA<SaveDone>());
      // oil_level 14 gün, bugün 2026-09-03 → sonraki 2026-09-17.
      expect((out as SaveDone).toast, 'Kaydedildi. Sonraki: 17 Eyl');

      final List<CheckLogRow> logs = await db.logDao.getAll();
      expect(logs.length, 1);
      expect(logs.single.itemId, id);
      expect(logs.single.doneDay, '2026-09-03');
      expect(logs.single.km, 118420);
      expect(logs.single.value, 'Orta');
      expect(logs.single.note, 'Yarım litre');

      final CheckItemRow row = (await db.itemDao.getById(id))!;
      expect(row.lastDoneDay, '2026-09-03');
      expect(row.lastDoneKm, 118420);
      expect(row.lastValue, 'Orta');
      expect(row.snoozeUntilDay, isNull);
    });

    test('tires değeri doğru biçimde saklanıyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'tire_pressure');
      await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(
              tires: <String>['2,3', '2.3', '2,3', '2,2'],
            ),
          );

      expect(
        (await db.itemDao.getById(id))!.lastValue,
        '2,3 / 2,3 / 2,3 / 2,2 bar',
      );
    });

    test('both maddede toast iki boyutu da veriyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'oil_change');
      final SaveOutcome out = await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(),
          );
      // 365 gün / 15.000 km, bugün 2026-09-03, km 118.420.
      expect(
        (out as SaveDone).toast,
        'Kaydedildi. Sonraki: 3 Eyl 2027 veya 133.420 km',
      );
    });

    test('boş not null olarak saklanıyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);
      final int id = await itemId(v, 'lights_horn');
      await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(note: '   '),
          );
      expect((await db.logDao.getAll()).single.note, isNull);
    });
  });

  // -------------------------------------------------------------- erteleme

  group('Yarın hatırlat', () {
    test('erteleme yarına, durum Yarın, ertesi gün tekrar gecikmiş', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(id, day: '2026-08-12', km: null);
      await c
          .read(itemDetailControllerProvider)
          .snoozeTomorrow((await db.itemDao.getById(id))!.toModel());

      expect((await db.itemDao.getById(id))!.snoozeUntilDay, '2026-09-04');

      // Bugün: soon "Yarın".
      final ProviderContainer c2 = makeContainer();
      await settle(c2);
      ItemStatus statusOf(ProviderContainer c) => c
          .read(statusesProvider)
          .firstWhere((dynamic e) => e.item.id == id)
          .status;
      expect(statusOf(c2).state, ItemState.soon);
      expect(statusOf(c2).shortText, S.tomorrow);

      // Ertesi gün: yine gecikmiş.
      final ProviderContainer c3 = ProviderContainer(
        overrides: <Override>[
          databaseProvider.overrideWithValue(db),
          seedProvider.overrideWithValue(seed),
          platformBridgeProvider.overrideWithValue(FakeBridge()),
          todayProvider.overrideWith((Ref ref) => DateTime(2026, 9, 4)),
          installDayProvider.overrideWith((Ref ref) => installDay),
        ],
      );
      addTearDown(c3.dispose);
      await settle(c3);
      expect(statusOf(c3).state, ItemState.overdue);
    });
  });

  // ------------------------------------------------------- tarih/km düzelt

  group('Tarih/km düzelt', () {
    test('K-23 kayıt satırı yazıyor, last_* değişiyor, unknown hesaplanıyor',
        () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);

      final int id = await itemId(v, 'timing_belt');
      ItemStatus statusOf(ProviderContainer c) => c
          .read(statusesProvider)
          .firstWhere((dynamic e) => e.item.id == id)
          .status;
      expect(statusOf(c).state, ItemState.unknown);

      await c
          .read(itemDetailControllerProvider)
          .fixLastDone(
            (await db.itemDao.getById(id))!.toModel(),
            day: DateTime(2022, 5, 10),
            km: 60000,
          );

      // K-23: düzeltme de bir kayıt satırı yazar, `fix` işaretli.
      final List<CheckLogRow> logs = await db.logDao.getAll();
      expect(logs.length, 1);
      expect(logs.single.kind, 'fix');
      expect(logs.single.doneDay, '2022-05-10');
      expect(logs.single.km, 60000);

      final CheckItemRow row = (await db.itemDao.getById(id))!;
      expect(row.lastDoneDay, '2022-05-10');
      expect(row.lastDoneKm, 60000);

      final ProviderContainer c2 = makeContainer();
      await settle(c2);
      expect(statusOf(c2).state, isNot(ItemState.unknown));
    });

    test('gün bazlı maddede km null bırakılıyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);
      final int id = await itemId(v, 'oil_level');
      await c
          .read(itemDetailControllerProvider)
          .fixLastDone(
            (await db.itemDao.getById(id))!.toModel(),
            day: DateTime(2026, 8, 12),
            km: null,
          );
      final CheckItemRow row = (await db.itemDao.getById(id))!;
      expect(row.lastDoneDay, '2026-08-12');
      // Gün bazlı maddede km uydurulmaz (K-23).
      expect(row.lastDoneKm, isNull);
      expect((await db.logDao.getAll()).single.km, isNull);
    });

    test('K-23: düzeltme, sonraki bir kayıt silinince kaybolmuyor', () async {
      final int v = await seedVehicle();
      final ProviderContainer c = makeContainer();
      await settle(c);
      final int id = await itemId(v, 'timing_belt');

      // Kullanıcı son yapılışı elle giriyor.
      await c
          .read(itemDetailControllerProvider)
          .fixLastDone(
            (await db.itemDao.getById(id))!.toModel(),
            day: DateTime(2022, 5, 10),
            km: 60000,
          );
      // Sonra "Yaptım" diyor.
      await c
          .read(itemDetailControllerProvider)
          .saveDone(
            item: (await db.itemDao.getById(id))!.toModel(),
            input: const MeasureInput(),
          );
      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-03');

      // Bu kaydı yanlışlıkla eklediğini fark edip siliyor.
      final CheckLogRow done = (await db.logDao.getAll()).firstWhere(
        (CheckLogRow r) => r.kind == 'done',
      );
      await db.logDao.deleteLog(done.id);

      // Elle girdiği değer geri geliyor; eskiden `unknown`a düşüyordu.
      final CheckItemRow row = (await db.itemDao.getById(id))!;
      expect(row.lastDoneDay, '2022-05-10');
      expect(row.lastDoneKm, 60000);
    });
  });

  // ------------------------------------------------- önceki kayıtlar metni

  group('önceki kayıt satırı', () {
    test('tam biçim', () {
      final CheckLog log = CheckLog(
        id: 1,
        itemId: 2,
        doneAt: DateTime(2026, 8, 16, 10),
        doneDay: '2026-08-16',
        km: 118100,
        value: '2,3 / 2,3 / 2,3 / 2,2 bar',
        note: 'Arka sağ düşük',
        kind: 'done',
      );
      expect(
        recentLogLine(log, refYear: 2026),
        '16 Ağu, 118.100 km, 2,3 / 2,3 / 2,3 / 2,2 bar. Arka sağ düşük',
      );
    });

    test('değersiz ve notsuz', () {
      final CheckLog log = CheckLog(
        id: 1,
        itemId: 2,
        doneAt: DateTime(2026, 8, 25, 10),
        doneDay: '2026-08-25',
        km: 118300,
        value: null,
        note: null,
        kind: 'done',
      );
      expect(recentLogLine(log, refYear: 2026), '25 Ağu, 118.300 km');
    });

    test('farklı yıl', () {
      final CheckLog log = CheckLog(
        id: 1,
        itemId: 2,
        doneAt: DateTime(2025, 3, 12, 10),
        doneDay: '2025-03-12',
        km: 104900,
        value: null,
        note: null,
        kind: 'done',
      );
      expect(recentLogLine(log, refYear: 2026), '12 Mar 2025, 104.900 km');
    });
  });

  // ------------------------------------------------------- widget testleri

  group('detay alt sayfası', () {
    Future<void> openDetail(
      WidgetTester tester,
      int vehicleId,
      String templateKey,
    ) async {
      await keepOnly(vehicleId, <String>{templateKey});
      final int id = await itemId(vehicleId, templateKey);
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
      await tester.tap(find.byKey(Key('item_$id')));
      await tester.pumpAndSettle();
    }

    Future<void> disposeTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
    }

    /// Alt sayfanın listesi tembel; hedef widget ekranın altındaysa
    /// önce oraya kaydırmak gerekiyor.
    Future<void> scrollSheetTo(WidgetTester tester, Finder target) async {
      await tester.scrollUntilVisible(
        target,
        160,
        scrollable: find
            .descendant(
              of: find.byType(ItemDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('level maddesi: zorunlu, seçilmeden kaydetmiyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'oil_level');

      expect(find.byKey(const Key('detail_title')), findsOneWidget);
      expect(find.text('Motor yağı seviyesi'), findsWidgets);
      await scrollSheetTo(tester, find.byKey(const Key('level_Orta')));
      expect(find.byKey(const Key('level_Orta')), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail_save')));
      await tester.pumpAndSettle();
      expect(find.text(S.errPickLevel), findsOneWidget);
      expect(await db.logDao.getAll(), isEmpty);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await disposeTree(tester);
    });

    testWidgets('level seçilince kaydediyor ve sayfa kapanıyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'oil_level');

      await scrollSheetTo(tester, find.byKey(const Key('level_Orta')));
      await tester.tap(find.byKey(const Key('level_Orta')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail_title')), findsNothing);
      expect((await db.logDao.getAll()).length, 1);
      expect(find.textContaining('Kaydedildi.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await disposeTree(tester);
    });

    testWidgets('tires maddesi dört alan ve hedef satırı gösteriyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle(front: 2.3, rear: 2.3);
      await openDetail(tester, v, 'tire_pressure');

      await scrollSheetTo(tester, find.byKey(const Key('tire_0')));
      expect(find.byKey(const Key('tire_0')), findsOneWidget);
      expect(find.byKey(const Key('tire_1')), findsOneWidget);
      expect(find.byKey(const Key('tire_2')), findsOneWidget);
      expect(find.byKey(const Key('tire_3')), findsOneWidget);
      expect(find.text('Hedef: ön 2,3 / arka 2,3'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('hedef tanımsızsa etiket metni gösteriliyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'tire_pressure');
      await scrollSheetTo(tester, find.byKey(const Key('tire_target')));
      expect(find.text(S.tireTargetUnknown), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('gecikmiş maddede Yarın hatırlat var, değilse yok', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      final int id = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(id, day: '2026-08-12', km: null);
      await openDetail(tester, v, 'oil_level');
      expect(find.byKey(const Key('detail_snooze')), findsOneWidget);
      await disposeTree(tester);

      await db.itemDao.setLastDone(id, day: '2026-09-01', km: null);
      await openDetail(tester, v, 'oil_level');
      expect(find.byKey(const Key('detail_snooze')), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('unknown maddede düzeltme öne çıkarılıyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'timing_belt');
      expect(find.byKey(const Key('detail_unknown_callout')), findsOneWidget);
      expect(find.text(S.detailUnknownCallout), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('yıl alanı bugünün yılıyla dolu açılıyor', (
      WidgetTester tester,
    ) async {
      // Cihaz testi bulgusu: yıl yalnız ipucuydu; kutu dolu görünüyor ama alan
      // boş olduğu için gün+ay girmek "Tarih gir" hatası veriyordu.
      final int v = await seedVehicle();
      final int id = await itemId(v, 'oil_level');
      await openDetail(tester, v, 'oil_level');

      await tester.tap(find.byKey(const Key('detail_fix')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('date_year')))
            .controller!
            .text,
        '${today.year}',
      );

      // Ay açılır listesine dokunmadan: madde tarihsiz, ay boş; yalnız gün
      // girip kaydetmek hâlâ eksik tarih. Ayı da seçince kayıt geçiyor.
      await tester.enterText(find.byKey(const Key('date_day')), '2');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('date_month')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eyl').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fix_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fix_error')), findsNothing);
      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-02');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await disposeTree(tester);
    });

    testWidgets('düzeltme diyaloğu ileri tarih kabul etmiyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      final int id = await itemId(v, 'oil_level');
      // Diyalog bu tarihle açılsın; yalnız günü ileriye çekiyoruz, böylece
      // ay açılır listesine dokunmaya gerek kalmıyor.
      await db.itemDao.setLastDone(id, day: '2026-09-01', km: null);
      await openDetail(tester, v, 'oil_level');

      await tester.tap(find.byKey(const Key('detail_fix')));
      await tester.pumpAndSettle();

      // 30 Eyl 2026, bugün 3 Eyl 2026 → ileri tarih.
      await tester.enterText(find.byKey(const Key('date_day')), '30');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fix_save')));
      await tester.pumpAndSettle();

      // Diyalog kapanmadı, uyarı çıktı, tarih değişmedi, kayıt açılmadı.
      expect(find.byKey(const Key('fix_error')), findsOneWidget);
      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-01');
      expect(await db.logDao.getAll(), isEmpty);

      await disposeTree(tester);
    });

    testWidgets('düzeltme geçmiş tarihi kaydediyor ve fix satırı yazıyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      final int id = await itemId(v, 'oil_level');
      await db.itemDao.setLastDone(id, day: '2026-09-01', km: null);
      await openDetail(tester, v, 'oil_level');

      await tester.tap(find.byKey(const Key('detail_fix')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('date_day')), '2');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fix_save')));
      await tester.pumpAndSettle();

      expect((await db.itemDao.getById(id))!.lastDoneDay, '2026-09-02');
      final List<CheckLogRow> logs = await db.logDao.getAll();
      expect(logs.length, 1);
      expect(logs.single.kind, 'fix');

      await disposeTree(tester);
    });

    testWidgets('km maddesinde düzeltme diyaloğunda km alanı var', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'air_filter');
      await tester.tap(find.byKey(const Key('detail_fix')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fix_km')), findsOneWidget);
      await disposeTree(tester);
    });

    testWidgets('gün maddesinde düzeltme diyaloğunda km alanı yok', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'oil_level');
      await tester.tap(find.byKey(const Key('detail_fix')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fix_km')), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('neden, nasıl ve servise git satırı görünüyor', (
      WidgetTester tester,
    ) async {
      final int v = await seedVehicle();
      await openDetail(tester, v, 'oil_level');
      expect(find.byKey(const Key('detail_why')), findsOneWidget);
      expect(find.text(S.detailHow), findsOneWidget);
      await scrollSheetTo(tester, find.byKey(const Key('detail_warn')));
      expect(find.byKey(const Key('detail_warn')), findsOneWidget);
      await disposeTree(tester);
    });
  });
}

/// Drift satırını domain modeline çeviren test kısayolu.
extension CheckItemRowToModel on CheckItemRow {
  CheckItem toModel() => ItemListRepo.toModel(this);
}
