import '../data/seed/seed_loader.dart';

/// DB'deki bir maddenin birleştirme için gereken asgari görünümü.
/// (Drift satırından da, testten de beslenebilsin diye ayrı tutuldu.)
class ExistingItem {
  const ExistingItem({required this.templateKey, required this.sortOrder});

  /// Kullanıcı maddesinde null.
  final String? templateKey;
  final int sortOrder;
}

/// Şablon sürüm yükseltme planı (K-07).
class MergePlan {
  const MergePlan({
    required this.toInsert,
    required this.unchangedCount,
    required this.removedFromSeed,
    required this.nextSortOrder,
  });

  /// Seed'de olup DB'de olmayan maddeler. Kurulumda hepsi; yükseltmede yalnız
  /// yeniler. Yükseltmede **kapalı** olarak eklenirler.
  final List<SeedItem> toInsert;

  /// Hem seed'de hem DB'de olan madde sayısı; bunlara dokunulmaz.
  final int unchangedCount;

  /// DB'de olup seed'de artık olmayan `template_key`'ler. Silinmezler
  /// (K-07: "Seed'den kaldırılan maddeler DB'de kalır"), yalnız raporlanır.
  final List<String> removedFromSeed;

  /// Eklenecek ilk maddenin `sort_order` değeri.
  final int nextSortOrder;

  bool get isEmpty => toInsert.isEmpty;
}

/// Saf birleştirme kuralı; yan etkisiz, testler buna.
abstract final class TemplateMerge {
  /// [dbItems] boşsa bu bir **ilk kurulum**dur: seed sırası korunur ve
  /// `enabled` seed'in `enabledByDefault` değeridir (çağıran uygular).
  /// Doluysa bu bir **sürüm yükseltme**dir: yalnız yeni maddeler eklenir,
  /// mevcut maddelerin kullanıcı değişiklikleri asla ezilmez.
  static MergePlan plan(List<SeedItem> seedItems, List<ExistingItem> dbItems) {
    final Set<String> dbKeys = <String>{
      for (final ExistingItem i in dbItems)
        if (i.templateKey != null) i.templateKey!,
    };
    final Set<String> seedKeys = <String>{
      for (final SeedItem s in seedItems) s.id,
    };

    final List<SeedItem> toInsert = <SeedItem>[
      for (final SeedItem s in seedItems)
        if (!dbKeys.contains(s.id)) s,
    ];

    final List<String> removed = <String>[
      for (final String k in dbKeys)
        if (!seedKeys.contains(k)) k,
    ]..sort();

    int maxSort = -1;
    for (final ExistingItem i in dbItems) {
      if (i.sortOrder > maxSort) {
        maxSort = i.sortOrder;
      }
    }

    return MergePlan(
      toInsert: List<SeedItem>.unmodifiable(toInsert),
      unchangedCount: seedItems.length - toInsert.length,
      removedFromSeed: List<String>.unmodifiable(removed),
      nextSortOrder: maxSort + 1,
    );
  }
}
