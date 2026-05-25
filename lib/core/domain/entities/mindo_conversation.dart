/// Representa uma sessão de conversa com o Mindo.
/// Cada usuário possui sua própria lista de sessões isoladas.
class MindoConversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessage;

  const MindoConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessage,
  });

  MindoConversation copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessage,
  }) =>
      MindoConversation(
        id: id,
        userId: userId,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messageCount: messageCount ?? this.messageCount,
        lastMessage: lastMessage ?? this.lastMessage,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'message_count': messageCount,
        'last_message': lastMessage,
      };

  factory MindoConversation.fromJson(Map<String, dynamic> json) =>
      MindoConversation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String? ?? 'Nova Conversa',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        messageCount: json['message_count'] as int? ?? 0,
        lastMessage: json['last_message'] as String?,
      );
}
