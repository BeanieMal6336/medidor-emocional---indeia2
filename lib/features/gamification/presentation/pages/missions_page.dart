import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../providers/missions_provider.dart';

class MissionsPage extends ConsumerStatefulWidget {
  const MissionsPage({super.key});

  @override
  ConsumerState<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends ConsumerState<MissionsPage> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getWeeklyCountdown() {
    final now = DateTime.now();
    int daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday <= 0) {
      daysUntilMonday += 7;
    }
    final nextMonday = DateTime(now.year, now.month, now.day + daysUntilMonday);
    final diff = nextMonday.difference(now);

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    return '${days}d ${hours}h ${minutes}m';
  }
  void _claimXp(String id, bool isDaily) {
    ref.read(missionsProvider.notifier).claimMission(id, isDaily);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accentGreen,
        content: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'XP resgatado com sucesso!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleManual(String id) {
    ref.read(missionsProvider.notifier).toggleManualMission(id, true);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final profile = profileAsync.value;
    final missionsState = ref.watch(missionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text(
          'Missões e Hábitos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: missionsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header stats card
                  _buildStatsCard(profile),
                  const SizedBox(height: AppSpacing.lg),

                  // Daily Title
                  Row(
                    children: [
                      const Text(
                        'Missões Diárias',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reseta à meia-noite',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...missionsState.daily
                      .asMap()
                      .entries
                      .map((e) => _buildMissionItem(e.value, true, e.key)
                          .animate(delay: Duration(milliseconds: e.key * 60))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1))
                      .toList(),

                  const SizedBox(height: AppSpacing.lg),

                  // Weekly Title
                  Row(
                    children: [
                      const Text(
                        'Desafios Semanais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reseta em: ${_getWeeklyCountdown()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...missionsState.weekly
                      .asMap()
                      .entries
                      .map((e) => _buildMissionItem(e.value, false, e.key)
                          .animate(delay: Duration(milliseconds: (e.key + 5) * 60))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1))
                      .toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(UserProfile? profile) {
    final String levelLabel = profile?.level.label ?? 'Sementinha';
    final String levelEmoji = profile?.level.emoji ?? '🌱';
    final int levelNum =
        (LevelType.values.indexOf(profile?.level ?? LevelType.seedling)) + 1;
    final int totalXp = profile?.totalXp ?? 0;
    final int streak = profile?.currentStreak ?? 0;

    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E1A4E), Color(0xFF1E1E35)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nível Atual',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(levelEmoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '$levelLabel (Nível $levelNum)',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$totalXp XP',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak dias',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (totalXp == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete missões para ganhar XP e subir de nível!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildMissionItem(MissionData mission, bool isDaily, int index) {
    final bool canClaim = mission.progress >= 1.0 && !mission.isClaimed;
    final bool isManualAndInProgress =
        mission.isManual && !mission.isClaimed && mission.progress < 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: mission.isClaimed
                        ? AppColors.accentGreen.withOpacity(0.15)
                        : AppColors.glass,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(mission.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: mission.isClaimed
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: mission.isClaimed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${mission.xp} XP',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (mission.isManual && !mission.isClaimed) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              'Marque manualmente quando concluir',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress bar + actions row
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: mission.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.glass,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mission.isClaimed
                            ? AppColors.accentGreen
                            : mission.progress >= 1.0
                                ? AppColors.accentGreen
                                : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(mission.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Action button
                if (mission.isClaimed)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.accentGreen, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Resgatado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (canClaim)
                  ElevatedButton(
                    onPressed: () => _claimXp(mission.id, isDaily),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Resgatar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (isManualAndInProgress)
                  GestureDetector(
                    onTap: () => _toggleManual(mission.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Text(
                        '✓ Feito',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'Em progresso',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
