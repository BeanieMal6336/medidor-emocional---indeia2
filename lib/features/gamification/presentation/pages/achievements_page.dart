import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../../app/router/app_router.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  String _getMonthAbbr(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Fev';
      case 3: return 'Mar';
      case 4: return 'Abr';
      case 5: return 'Mai';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Ago';
      case 9: return 'Set';
      case 10: return 'Out';
      case 11: return 'Nov';
      case 12: return 'Dez';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final moodEntriesAsync = ref.watch(moodNotifierProvider);

    final profile = profileAsync.value;
    final moodEntries = moodEntriesAsync.value ?? [];

    final String joinDate = profile != null
        ? '${profile.createdAt.day} ${_getMonthAbbr(profile.createdAt.month)} ${profile.createdAt.year}'
        : '24 Mai 2026';

    final hasFirstStep = moodEntries.isNotEmpty;
    final hasStreak7 = (profile?.longestStreak ?? 0) >= 7;
    final hasConversador = (profile?.totalXp ?? 0) >= 150; 
    final hasExplorador = moodEntries.expand((e) => e.triggers).toSet().length >= 3; // Let's make it 3 triggers for easier unlocks
    final hasZen = (profile?.totalXp ?? 0) >= 300; 

    final List<_AchievementModel> achievements = [
      _AchievementModel(
        title: 'Primeiro Passo',
        description: 'Registrou seu humor pela primeira vez.',
        emoji: '🌱',
        xpReward: 50,
        isUnlocked: hasFirstStep,
        unlockedDate: hasFirstStep ? joinDate : null,
        rarity: 'Comum',
        rarityColor: AppColors.accentGreen,
      ),
      _AchievementModel(
        title: 'Sem Parar',
        description: 'Mantenha um streak emocional de 7 dias.',
        emoji: '🔥',
        xpReward: 100,
        isUnlocked: hasStreak7,
        unlockedDate: hasStreak7 ? joinDate : null,
        rarity: 'Comum',
        rarityColor: AppColors.accentGreen,
      ),
      _AchievementModel(
        title: 'Conversador Nato',
        description: 'Alcance 150+ XP no total.',
        emoji: '💬',
        xpReward: 150,
        isUnlocked: hasConversador,
        unlockedDate: hasConversador ? joinDate : null,
        rarity: 'Raro',
        rarityColor: AppColors.accentBlue,
      ),
      _AchievementModel(
        title: 'Explorador Mental',
        description: 'Identificou 3 gatilhos emocionais diferentes.',
        emoji: '🗺️',
        xpReward: 200,
        isUnlocked: hasExplorador,
        unlockedDate: hasExplorador ? joinDate : null,
        rarity: 'Épico',
        rarityColor: AppColors.primary,
      ),
      _AchievementModel(
        title: 'Monge Zen',
        description: 'Evolua seu perfil até 300+ XP.',
        emoji: '🧘',
        xpReward: 500,
        isUnlocked: hasZen,
        unlockedDate: hasZen ? joinDate : null,
        rarity: 'Lendário',
        rarityColor: AppColors.accent,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: const Text('Conquistas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final ach = achievements[index];
          return _buildAchievementItem(ach).animate().fadeIn(
                duration: 400.ms,
                delay: (index * 100).ms,
              ).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildAchievementItem(_AchievementModel ach) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        color: ach.isUnlocked ? null : AppColors.glass.withOpacity(0.02),
        borderColor: ach.isUnlocked ? null : AppColors.glassBorder.withOpacity(0.05),
        child: Row(
          children: [
            // Badge / Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ach.isUnlocked
                    ? ach.rarityColor.withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ach.isUnlocked
                      ? ach.rarityColor.withOpacity(0.5)
                      : AppColors.glassBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: ach.isUnlocked ? 1.0 : 0.25,
                  child: Text(
                    ach.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Achievement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ach.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ach.isUnlocked
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ach.rarityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ach.rarityColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ach.rarity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ach.rarityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ach.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: ach.isUnlocked
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '+${ach.xpReward} XP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ach.isUnlocked ? AppColors.accent : AppColors.textDisabled,
                        ),
                      ),
                      if (ach.isUnlocked && ach.unlockedDate != null)
                        Text(
                          'Desbloqueado em ${ach.unlockedDate}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        )
                      else if (!ach.isUnlocked)
                        const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: AppColors.textDisabled),
                            SizedBox(width: 4),
                            Text(
                              'Bloqueado',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textDisabled,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementModel {
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final bool isUnlocked;
  final String? unlockedDate;
  final String rarity;
  final Color rarityColor;

  _AchievementModel({
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedDate,
    required this.rarity,
    required this.rarityColor,
  });
}
