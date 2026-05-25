class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String rarity; // common, rare, epic, legendary

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.xpReward,
    this.rarity = 'common',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'category': category,
    'is_unlocked': isUnlocked,
    'unlocked_at': unlockedAt?.toIso8601String(),
    'xp_reward': xpReward,
    'rarity': rarity,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    category: json['category'] as String,
    isUnlocked: json['is_unlocked'] as bool? ?? false,
    unlockedAt: json['unlocked_at'] != null
        ? DateTime.parse(json['unlocked_at'] as String)
        : null,
    xpReward: json['xp_reward'] as int,
    rarity: json['rarity'] as String? ?? 'common',
  );
}
