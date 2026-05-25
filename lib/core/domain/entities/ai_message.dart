enum MessageRole { user, assistant, system }

class AiMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final bool isLoading;

  const AiMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.isLoading = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
    id: json['id'] as String,
    content: json['content'] as String,
    role: MessageRole.values.byName(json['role'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  AiMessage copyWith({String? content, bool? isLoading}) => AiMessage(
    id: id,
    content: content ?? this.content,
    role: role,
    createdAt: createdAt,
    isLoading: isLoading ?? this.isLoading,
  );
}
