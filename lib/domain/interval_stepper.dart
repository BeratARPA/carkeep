/// Aralık adımlayıcısı (01-spec §3.7, K-19). Saf; yan etkisiz.
library;

/// [current] değerinden [direction] yönünde bir sonraki preset.
///
/// * Preset üzerindeyse bir komşuya geçer.
/// * Preset dışındaysa o yöndeki en yakın preset'e atlar (K-19).
/// * Uçlarda durur; liste boşsa değer değişmez.
int stepInterval(int current, List<int> presets, int direction) {
  if (presets.isEmpty || direction == 0) {
    return current;
  }
  if (direction > 0) {
    for (final int p in presets) {
      if (p > current) {
        return p;
      }
    }
    // Zaten en üstte veya daha büyük: uçta dur.
    return current > presets.last ? current : presets.last;
  }
  for (int i = presets.length - 1; i >= 0; i--) {
    if (presets[i] < current) {
      return presets[i];
    }
  }
  return current < presets.first ? current : presets.first;
}

/// Adımlayıcı bu yönde bir şey değiştirebilir mi (uçta butonu söndürmek için).
bool canStepInterval(int current, List<int> presets, int direction) =>
    stepInterval(current, presets, direction) != current;
