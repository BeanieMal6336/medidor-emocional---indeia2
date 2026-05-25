import '../enums/mission_status.dart';

class Mission {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final MissionStatus status;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final String category; // sleep, hydration, movement, social, mindfulness
  final int targetCount;
  final int currentCount;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    this.status = MissionStatus.available,
    this.completedAt,
    required this.expiresAt,
    required this.category,
    this.targetCount = 1,
    this.currentCount = 0,
  });

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
  bool get isCompleted => status == MissionStatus.completed;
  bool get isExpired => DateTime.now().isAfter(expiresAt) && !isCompleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'xp_reward': xpReward,
    'status': status.name,
    'completed_at': completedAt?.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'category': category,
    'target_count': targetCount,
    'current_count': currentCount,
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    xpReward: json['xp_reward'] as int,
    status: MissionStatus.values.byName(json['status'] as String? ?? 'available'),
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    category: json['category'] as String,
    targetCount: json['target_count'] as int? ?? 1,
    currentCount: json['current_count'] as int? ?? 0,
  );

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    int? xpReward,
    MissionStatus? status,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? category,
    int? targetCount,
    int? currentCount,
  }) => Mission(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    emoji: emoji ?? this.emoji,
    xpReward: xpReward ?? this.xpReward,
    status: status ?? this.status,
    completedAt: completedAt ?? this.completedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    category: category ?? this.category,
    targetCount: targetCount ?? this.targetCount,
    currentCount: currentCount ?? this.currentCount,
  );
}
