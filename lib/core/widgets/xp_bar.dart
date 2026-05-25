import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final String levelLabel;
  final String levelEmoji;
  final double height;

  const XpBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    required this.levelLabel,
    required this.levelEmoji,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(levelEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  levelLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$currentXp / $maxXp XP',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                color: AppColors.glass,
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                widthFactor: progress,
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
