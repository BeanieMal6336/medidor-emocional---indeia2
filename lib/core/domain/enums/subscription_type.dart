enum SubscriptionType {
  free,
  silver,
  gold;

  String get label {
    switch (this) {
      case free:   return 'Gratuito';
      case silver: return 'Silver';
      case gold:   return 'Gold';
    }
  }

  String get emoji {
    switch (this) {
      case free:   return '🌱';
      case silver: return '🥈';
      case gold:   return '👑';
    }
  }

  bool get isPremium => this == silver || this == gold;
  bool get isGold    => this == gold;
  bool get isSilver  => this == silver;

  // Serialisation helpers
  String toJson() => name;

  static SubscriptionType fromJson(String? value) {
    switch (value) {
      case 'silver': return silver;
      case 'gold':   return gold;
      default:       return free;
    }
  }
}
