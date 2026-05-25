class Insight {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String type; // pattern, trigger, suggestion, achievement
  final String emoji;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const Insight({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.emoji,
    required this.createdAt,
    this.isRead = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'type': type,
    'emoji': emoji,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'metadata': metadata,
  };

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    type: json['type'] as String,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    isRead: json['is_read'] as bool? ?? false,
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );

  Insight copyWith({bool? isRead}) => Insight(
    id: id,
    userId: userId,
    title: title,
    content: content,
    type: type,
    emoji: emoji,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    metadata: metadata,
  );
}
