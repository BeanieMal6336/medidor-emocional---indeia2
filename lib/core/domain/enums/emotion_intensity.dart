enum EmotionIntensity {
  light,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case light: return 'Leve';
      case moderate: return 'Moderado';
      case high: return 'Alto';
      case critical: return 'Crítico';
    }
  }

  static EmotionIntensity fromValue(int value) {
    if (value <= 3) return light;
    if (value <= 5) return moderate;
    if (value <= 8) return high;
    return critical;
  }
}
