import 'emotion.dart';

class EmotionEntry {
  final String id;
  final String userId;
  final DateTime createdAt;
  final List<Emotion> emotions;
  final String? note;
  final List<String> triggers;
  final List<String> physicalSymptoms;
  final List<String> socialContext;
  final int overallMood; // 1-10
  final String? voiceNoteUrl;
  final int xpEarned;

  const EmotionEntry({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.emotions,
    this.note,
    this.triggers = const [],
    this.physicalSymptoms = const [],
    this.socialContext = const [],
    required this.overallMood,
    this.voiceNoteUrl,
    this.xpEarned = 10,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'emotions': emotions.map((e) => e.toJson()).toList(),
    'note': note,
    'triggers': triggers,
    'physical_symptoms': physicalSymptoms,
    'social_context': socialContext,
    'overall_mood': overallMood,
    'voice_note_url': voiceNoteUrl,
    'xp_earned': xpEarned,
  };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) => EmotionEntry(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    emotions: (json['emotions'] as List)
        .map((e) => Emotion.fromJson(e as Map<String, dynamic>))
        .toList(),
    note: json['note'] as String?,
    triggers: List<String>.from(json['triggers'] ?? []),
    physicalSymptoms: List<String>.from(json['physical_symptoms'] ?? []),
    socialContext: List<String>.from(json['social_context'] ?? []),
    overallMood: json['overall_mood'] as int,
    voiceNoteUrl: json['voice_note_url'] as String?,
    xpEarned: json['xp_earned'] as int? ?? 10,
  );

  EmotionEntry copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    List<Emotion>? emotions,
    String? note,
    List<String>? triggers,
    List<String>? physicalSymptoms,
    List<String>? socialContext,
    int? overallMood,
    String? voiceNoteUrl,
    int? xpEarned,
  }) => EmotionEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    emotions: emotions ?? this.emotions,
    note: note ?? this.note,
    triggers: triggers ?? this.triggers,
    physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
    socialContext: socialContext ?? this.socialContext,
    overallMood: overallMood ?? this.overallMood,
    voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
    xpEarned: xpEarned ?? this.xpEarned,
  );
}
