import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../../app/router/app_router.dart';
import '../../../gamification/providers/missions_provider.dart';
import '../providers/auth_provider.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final profile = profileAsync.value;
    
    final String displayName = profile?.displayName ?? user?.email?.split('@').first ?? 'Viajante';
    final String email = profile?.email ?? user?.email ?? 'offline@mindflow.app';
    final int streak = profile?.currentStreak ?? 0;
    
    // XP and level calculations
    final int totalXp = profile?.totalXp ?? 0;
    final LevelType currentLevel = profile?.level ?? LevelType.seedling;
    final String levelLabel = currentLevel.label;
    final String levelEmoji = currentLevel.emoji;
    final int levelNum = (LevelType.values.indexOf(currentLevel)) + 1;
    
    final int currentLevelMinXp = currentLevel.xpRequired;
    final nextLevel = LevelType.values
        .skipWhile((l) => l != currentLevel)
        .skip(1)
        .firstOrNull;
    final int nextLevelXp = nextLevel?.xpRequired ?? (currentLevelMinXp + 500);
    
    final int relativeXp = totalXp - currentLevelMinXp;
    final int relativeMaxXp = nextLevelXp - currentLevelMinXp;

    // Claimed missions count
    final missionsState = ref.watch(missionsProvider);
    final claimedMissionsCount = [
      ...missionsState.daily,
      ...missionsState.weekly
    ].where((m) => m.isClaimed).length;

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
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        title: const Text('Meu Perfil Emocional', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Profile Header / Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadowPrimary,
                    ),
                    child: const Center(
                      child: Text(
                        '😊',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Level & XP details
            GlassCard(
              child: XpBar(
                currentXp: relativeXp,
                maxXp: relativeMaxXp,
                levelLabel: '$levelLabel (Nível $levelNum)',
                levelEmoji: levelEmoji,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Stats row (Streak & Completed missions)
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Dias seguidos',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Text(
                          '🎯',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$claimedMissionsCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Missões ganhas',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Logout/Support actions card
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    onTap: () => context.push(AppRoutes.achievements),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AppColors.accentGreen, size: 20),
                    ),
                    title: const Text('Minhas Conquistas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Ver troféus e recompensas desbloqueadas', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () {},
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
                    ),
                    title: const Text('MindFlow Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Desbloquear relatórios completos e voz IA', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    ),
                    title: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
