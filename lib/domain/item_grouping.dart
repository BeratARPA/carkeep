/// Ana ekran bölümleme ve sıralama (01-spec §2.5, K-17). Yan etkisiz.
library;

import '../core/date_utils.dart';
import 'models/check_item.dart';
import 'models/item_status.dart';

/// Bir madde ve hesaplanmış durumu.
typedef StatusedItem = ({CheckItem item, ItemStatus status});

/// Bölümlere ayrılmış, her bölüm kendi içinde sıralanmış liste.
class GroupedItems {
  const GroupedItems({
    required this.overdue,
    required this.soon,
    required this.ok,
    required this.unknown,
  });

  final List<StatusedItem> overdue;
  final List<StatusedItem> soon;
  final List<StatusedItem> ok;
  final List<StatusedItem> unknown;

  /// Gecikmiş ve yaklaşan ikisi de boşsa ana ekran "her şey zamanında" der.
  bool get nothingPending => overdue.isEmpty && soon.isEmpty;

  int get total => overdue.length + soon.length + ok.length + unknown.length;
}

/// Kapalı maddeler ana ekranda görünmez (01-spec §2.5).
///
/// Sıralama iki anahtarlı:
/// * `overdue` → artan [ItemStatus.sortKey] (bağlayıcı oran, K-17).
///   01-spec §2.5'in emrettiği kural: en çok gecikmiş önce.
/// * `soon` ve `ok` → artan [ItemStatus.proximityKey] (K-22).
///   §2.5 "en yakın önce" diyor; oran bunu vermiyordu (seyrek aralıklı bir
///   madde, yakın tarihli sık maddenin üstüne çıkıyordu).
/// * `unknown` → şablon sırası.
GroupedItems groupForHome(List<StatusedItem> all) {
  final List<StatusedItem> overdue = <StatusedItem>[];
  final List<StatusedItem> soon = <StatusedItem>[];
  final List<StatusedItem> ok = <StatusedItem>[];
  final List<StatusedItem> unknown = <StatusedItem>[];

  for (final StatusedItem e in all) {
    if (!e.item.enabled) {
      continue;
    }
    switch (e.status.state) {
      case ItemState.overdue:
        overdue.add(e);
      case ItemState.soon:
        soon.add(e);
      case ItemState.ok:
        ok.add(e);
      case ItemState.unknown:
        unknown.add(e);
    }
  }

  overdue.sort(compareBySortKey);
  soon.sort(compareByProximity);
  ok.sort(compareByProximity);
  unknown.sort(compareBySortOrder);

  return GroupedItems(
    overdue: List<StatusedItem>.unmodifiable(overdue),
    soon: List<StatusedItem>.unmodifiable(soon),
    ok: List<StatusedItem>.unmodifiable(ok),
    unknown: List<StatusedItem>.unmodifiable(unknown),
  );
}

/// Artan `sortKey` (gecikmiş); eşitlikte şablon sırası (kararlı sonuç için).
int compareBySortKey(StatusedItem a, StatusedItem b) {
  final int byKey = a.status.sortKey.compareTo(b.status.sortKey);
  return byKey != 0 ? byKey : compareBySortOrder(a, b);
}

/// Artan `proximityKey` (yaklaşan, zamanında); eşitlikte şablon sırası.
int compareByProximity(StatusedItem a, StatusedItem b) {
  final int byKey = a.status.proximityKey.compareTo(b.status.proximityKey);
  return byKey != 0 ? byKey : compareBySortOrder(a, b);
}

int compareBySortOrder(StatusedItem a, StatusedItem b) {
  final int bySort = a.item.sortOrder.compareTo(b.item.sortOrder);
  return bySort != 0 ? bySort : a.item.id.compareTo(b.item.id);
}

/// `yyyy-MM-dd` leksikografik karşılaştırma = kronolojik (K-10).
bool _snoozed(String? until, String todayKey) =>
    until != null && until.compareTo(todayKey) > 0;

/// Motorun bildirim için "gecikmiş" saydıkları: kapalı maddeler ve **ertelenmiş**
/// olanlar hariç (01-spec §7.1 adım 5).
///
/// Ana ekranın Gecikmiş bölümünden farkı erteleme: K-13 gereği ertelenmiş madde
/// ekranda gecikmiş görünmeye devam eder, ama bildirime girmez. K-27 bu sayıyı
/// kullanır.
List<StatusedItem> engineOverdue(List<StatusedItem> all, DateTime today) {
  final String todayKey = dayKey(today);
  return <StatusedItem>[
    for (final StatusedItem e in all)
      if (e.item.enabled &&
          e.status.state == ItemState.overdue &&
          !_snoozed(e.item.snoozeUntilDay, todayKey))
        e,
  ];
}
