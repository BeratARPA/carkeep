/// Sayısal sabitler ve eşikler. Ürün kararları `docs/01-spec.md`'de.
library;

/// Platform köprüsü kanal adı (02-mimari §6, K-05).
const String kPlatformChannel = 'com.beratarpa.carkeep/platform';

/// Snapshot şema sürümü (02-mimari §5).
const int kSnapshotVersion = 1;

// ---------------------------------------------------------------------------
// "Yaklaşan" eşikleri (01-spec §2.3)
// ---------------------------------------------------------------------------

/// Gün bazlı maddede `daysLeft <= 3` → yaklaşan.
const int kSoonDays = 3;

/// Km bazlı maddede `kmLeft <= 1000` → yaklaşan.
const int kSoonKm = 1000;

/// Mevsimsel maddede `daysLeft <= 14` → yaklaşan.
const int kSoonSeasonalDays = 14;

// ---------------------------------------------------------------------------
// Kural varsayılanları (01-spec §3.7, §7)
// ---------------------------------------------------------------------------

const bool kDefaultOnlyOverdue = true;
const bool kDefaultOncePerDay = true;

/// Dakika, 1–30.
const int kDefaultMinTripMinutes = 5;
const int kMinTripMinutesMin = 1;
const int kMinTripMinutesMax = 30;

/// Dakika, 0–5. Hızlı geri bağlanma toleransı (K-06).
const int kDefaultGraceMinutes = 2;
const int kGraceMinutesMin = 0;
const int kGraceMinutesMax = 5;

/// Gün; 0 = kapalı. Sürüşsüz dönem yedeği (K-12).
const int kDefaultFallbackAfterDays = 7;

/// Ayarlardaki seçenekler: kapalı / 3 / 7 / 14 gün.
const List<int> kFallbackAfterDaysOptions = <int>[0, 3, 7, 14];

// ---------------------------------------------------------------------------
// Aralık adımlayıcı presetleri (01-spec §3.7)
// ---------------------------------------------------------------------------

const List<int> kIntervalDaysPresets = <int>[
  7,
  14,
  30,
  60,
  90,
  180,
  365,
  730,
  1825,
];

const List<int> kIntervalKmPresets = <int>[
  5000,
  10000,
  15000,
  20000,
  30000,
  60000,
  80000,
  120000,
];

// ---------------------------------------------------------------------------
// Ölçüm
// ---------------------------------------------------------------------------

/// Hedeften bu kadar veya daha fazla sapan lastik alanı amber vurgulanır
/// (01-spec §3.3, bilgi amaçlı, engel değil).
const double kTirePressureDeviationBar = 0.3;

// ---------------------------------------------------------------------------
// Diğer
// ---------------------------------------------------------------------------

/// Snapshot yazımı için debounce süresi (02-mimari §9).
const Duration kSnapshotDebounce = Duration(milliseconds: 300);

/// Detay sayfasında gösterilen önceki kayıt sayısı (01-spec §3.3).
const int kRecentLogCount = 3;

/// Bildirim metninde virgülle listelenen en fazla madde adı (01-spec §3.8).
const int kNotificationNamePreviewCount = 3;
