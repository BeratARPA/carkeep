/// Ana ekran bölümleme ve sıralama (01-spec §2.5, K-17). Yan etkisiz.
library;

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
/// Sıralama (K-17): `overdue`, `soon` ve `ok` bölümlerinde artan `sortKey`
/// (bağlayıcı kalan / bağlayıcı aralık). `unknown` şablon sırasında kalır.
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
  soon.sort(compareBySortKey);
  ok.sort(compareBySortKey);
  unknown.sort(compareBySortOrder);

  return GroupedItems(
    overdue: List<StatusedItem>.unmodifiable(overdue),
    soon: List<StatusedItem>.unmodifiable(soon),
    ok: List<StatusedItem>.unmodifiable(ok),
    unknown: List<StatusedItem>.unmodifiable(unknown),
  );
}

/// Artan `sortKey`; eşitlikte şablon sırası (kararlı sonuç için).
int compareBySortKey(StatusedItem a, StatusedItem b) {
  final int byKey = a.status.sortKey.compareTo(b.status.sortKey);
  return byKey != 0 ? byKey : compareBySortOrder(a, b);
}

int compareBySortOrder(StatusedItem a, StatusedItem b) {
  final int bySort = a.item.sortOrder.compareTo(b.item.sortOrder);
  return bySort != 0 ? bySort : a.item.id.compareTo(b.item.id);
}
