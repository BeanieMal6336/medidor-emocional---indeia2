import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../domain/enums/emotion_type.dart';

class EmotionChip extends StatelessWidget {
  final EmotionType emotion;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const EmotionChip({
    super.key,
    required this.emotion,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  Color get _emotionColor {
    if (color != null) return color!;
    switch (emotion) {
      case EmotionType.joy: return AppColors.emotionJoy;
      case EmotionType.sadness: return AppColors.emotionSadness;
      case EmotionType.anger: return AppColors.emotionAnger;
      case EmotionType.fear: return AppColors.emotionFear;
      case EmotionType.anxiety: return AppColors.emotionAnxiety;
      case EmotionType.hope: return AppColors.emotionHope;
      case EmotionType.love: return AppColors.emotionLove;
      case EmotionType.calm: return AppColors.emotionCalm;
      case EmotionType.surprise: return AppColors.emotionSurprise;
      case EmotionType.disgust: return AppColors.emotionDisgust;
      case EmotionType.loneliness: return AppColors.emotionLoneliness;
      case EmotionType.guilt: return AppColors.emotionGuilt;
      case EmotionType.motivation: return AppColors.emotionMotivation;
      case EmotionType.exhaustion: return AppColors.emotionExhaustion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _emotionColor.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? _emotionColor : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _emotionColor.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emotion.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              emotion.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _emotionColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
