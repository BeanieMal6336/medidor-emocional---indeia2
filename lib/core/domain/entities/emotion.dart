import '../enums/emotion_type.dart';

class Emotion {
  final EmotionType type;
  final int intensity; // 1-10

  const Emotion({
    required this.type,
    required this.intensity,
  });

  String get label => type.label;
  String get emoji => type.emoji;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'intensity': intensity,
  };

  factory Emotion.fromJson(Map<String, dynamic> json) => Emotion(
    type: EmotionType.values.byName(json['type'] as String),
    intensity: json['intensity'] as int,
  );

  Emotion copyWith({EmotionType? type, int? intensity}) => Emotion(
    type: type ?? this.type,
    intensity: intensity ?? this.intensity,
  );
}
