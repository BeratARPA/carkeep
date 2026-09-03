import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/format_tr.dart';
import '../../core/strings_tr.dart';
import '../../domain/models/check_item.dart';
import '../../domain/models/check_log.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/measure.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/status_calculator.dart';
import '../../providers.dart';

/// Ölçüm alanlarının kullanıcı girdisi (01-spec §3.3).
class MeasureInput {
  const MeasureInput({
    this.level,
    this.tires = const <String>['', '', '', ''],
    this.number = '',
    this.note = '',
  });

  /// `level` için seçilen çip.
  final String? level;

  /// `tires` için ön sol, ön sağ, arka sol, arka sağ.
  final List<String> tires;

  /// `number` için tek alan.
  final String number;

  final String note;

  MeasureInput copyWith({
    Object? level = _sentinel,
    List<String>? tires,
    String? number,
    String? note,
  }) {
    return MeasureInput(
      level: level == _sentinel ? this.level : level as String?,
      tires: tires ?? this.tires,
      number: number ?? this.number,
      note: note ?? this.note,
    );
  }

  MeasureInput withTire(int index, String value) {
    final List<String> next = List<String>.of(tires);
    next[index] = value;
    return copyWith(tires: next);
  }

  static const Object _sentinel = Object();
}

/// Kaydetme sonucu; ekran toast'ı buna göre gösterir.
sealed class SaveOutcome {
  const SaveOutcome();
}

class SaveInvalid extends SaveOutcome {
  const SaveInvalid(this.message);

  final String message;
}

class SaveDone extends SaveOutcome {
  const SaveDone(this.toast);

  /// `Kaydedildi. Sonraki: 16 Eyl`
  final String toast;
}

class ItemDetailController {
  const ItemDetailController(this.ref);

  final Ref ref;

  /// Zorunlu ölçüm eksikse [SaveInvalid], değilse kaydeder (01-spec §3.3).
  Future<SaveOutcome> saveDone({
    required CheckItem item,
    required MeasureInput input,
  }) async {
    final String? problem = validateMeasure(item.measure, input);
    if (problem != null) {
      return SaveInvalid(problem);
    }

    final Vehicle? vehicle = ref.read(vehicleProvider).valueOrNull;
    if (vehicle == null) {
      return const SaveInvalid(S.errGeneric);
    }

    final DateTime today = ref.read(todayProvider);
    final String? value = buildMeasureValue(item.measure, input);
    final String note = input.note.trim();

    await ref
        .read(logRepoProvider)
        .add(
          itemId: item.id,
          doneAt: DateTime.now(),
          doneDay: dayKey(today),
          km: vehicle.currentKm,
          value: value,
          note: note.isEmpty ? null : note,
        );

    // Yeni son yapılışa göre bir sonraki vade (01-spec §3.3 toast'ı).
    final CheckItem updated = item.copyWith(
      lastDoneDay: dayKey(today),
      lastDoneKm: vehicle.currentKm,
      lastValue: value,
      snoozeUntilDay: null,
    );
    final String next = nextDueTextFor(
      item: updated,
      currentKm: vehicle.currentKm,
      installDay: ref.read(installDayProvider) ?? today,
      today: today,
    );

    return SaveDone(
      next.isEmpty ? S.savedPrefix : '${S.savedPrefix} $next',
    );
  }

  /// "Yarın hatırlat" (01-spec §3.3).
  Future<void> snoozeTomorrow(CheckItem item) async {
    final DateTime today = ref.read(todayProvider);
    await ref
        .read(itemListRepoProvider)
        .setSnooze(item.id, dayKey(addDays(today, 1)));
  }

  /// "Tarih/km düzelt" (01-spec §3.4). **Log oluşturmaz.**
  Future<void> fixLastDone(
    CheckItem item, {
    required DateTime day,
    required int? km,
  }) async {
    await ref
        .read(itemListRepoProvider)
        .setLastDone(item.id, day: dayKey(day), km: km);
  }

  Future<List<CheckLog>> recentLogs(int itemId) =>
      ref.read(logRepoProvider).recent(itemId);
}

final Provider<ItemDetailController> itemDetailControllerProvider =
    Provider<ItemDetailController>(ItemDetailController.new);

// ---------------------------------------------------------------- saf yardımcılar

/// Zorunlu ölçüm eksikse uyarı metni, değilse null (01-spec §3.3).
String? validateMeasure(Measure measure, MeasureInput input) {
  switch (measure.type) {
    case MeasureType.level:
      return (input.level == null || input.level!.isEmpty)
          ? S.errPickLevel
          : null;
    case MeasureType.tires:
      final bool allFour = input.tires.length == 4 &&
          input.tires.every((String t) => parseBar(t) != null);
      return allFour ? null : S.errAllFourTires;
    case MeasureType.number:
    case MeasureType.none:
      return null;
  }
}

/// `check_logs.value` ve `check_items.last_value` için saklanan metin.
String? buildMeasureValue(Measure measure, MeasureInput input) {
  switch (measure.type) {
    case MeasureType.none:
      return null;
    case MeasureType.level:
      return input.level;
    case MeasureType.tires:
      final List<double> bars = <double>[
        for (final String t in input.tires) parseBar(t)!,
      ];
      return formatTires(bars);
    case MeasureType.number:
      final double? v = parseBar(input.number);
      if (v == null) {
        return null;
      }
      return formatNumberMeasure(v, measure.unit ?? '');
  }
}

/// Girilen basınç hedeften [kTirePressureDeviationBar] veya daha fazla
/// sapıyor mu (01-spec §3.3; bilgi amaçlı, engel değil).
///
/// Karşılaştırma onda birlik adımlarda: `2,3 - 2,0` çift duyarlıkta
/// 0,29999999999999982 çıkıyor ve doğrudan `>= 0,3` yanlış sonuç veriyor.
bool tireDeviates(String raw, double? target) {
  if (target == null) {
    return false;
  }
  final double? value = parseBar(raw);
  if (value == null) {
    return false;
  }
  final int deltaTenths = ((value - target).abs() * 10).round();
  final int thresholdTenths = (kTirePressureDeviationBar * 10).round();
  return deltaTenths >= thresholdTenths;
}

/// `Hedef: ön 2,3 / arka 2,3`; ikisi de yoksa null.
String? tireTargetText({double? front, double? rear}) {
  final List<String> parts = <String>[
    if (front != null) '${S.tireTargetFront} ${formatBar(front)}',
    if (rear != null) '${S.tireTargetRear} ${formatBar(rear)}',
  ];
  if (parts.isEmpty) {
    return null;
  }
  return '${S.tireTargetPrefix} ${parts.join(' / ')}';
}

/// Lastik alanının hedefi: ilk ikisi ön, son ikisi arka.
double? tireTargetFor(int index, {double? front, double? rear}) =>
    index < 2 ? front : rear;

/// Kayıt sonrası toast'ın "Sonraki: …" kısmı (01-spec §3.3).
/// Hesap yine `StatusCalculator`'dan geçer (K-04).
String nextDueTextFor({
  required CheckItem item,
  required int currentKm,
  required DateTime installDay,
  required DateTime today,
}) {
  final ItemStatus status = StatusCalculator.compute(
    item: item,
    currentKm: currentKm,
    installDay: installDay,
    today: today,
  );
  return nextDueText(
    dueDay: status.dueDay,
    dueKm: status.dueKm,
    refYear: today.year,
  );
}
