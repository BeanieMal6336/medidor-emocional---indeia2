import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class MissionsPage extends ConsumerStatefulWidget {
  const MissionsPage({super.key});

  @override
  ConsumerState<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends ConsumerState<MissionsPage> {
  final List<_MissionModel> _dailyMissions = [
    _MissionModel(
      id: '1',
      emoji: '💧',
      title: 'Beber 2L de água',
      description: 'Mantenha seu corpo hidratado para ajudar na clareza mental.',
      xp: 20,
      progress: 1.0,
      category: 'Saúde',
      isCompleted: true,
    ),
    _MissionModel(
      id: '2',
      emoji: '🚶',
      title: 'Caminhar 15 minutos',
      description: 'Uma caminhada leve ajuda a clarear a mente e reduzir o cortisol.',
      xp: 30,
      progress: 0.5,
      category: 'Corpo',
      isCompleted: false,
    ),
    _MissionModel(
      id: '3',
      emoji: '✍️',
      title: 'Escrever 3 pensamentos',
      description: 'Coloque no papel tudo o que está tirando seu foco.',
      xp: 25,
      progress: 0.0,
      category: 'Mente',
      isCompleted: false,
    ),
  ];

  final List<_MissionModel> _weeklyMissions = [
    _MissionModel(
      id: '4',
      emoji: '🧘',
      title: '5 sessões de respiração',
      description: 'Pratique a respiração consciente guiada com o Mindo.',
      xp: 100,
      progress: 0.6,
      category: 'Mindfulness',
      isCompleted: false,
    ),
    _MissionModel(
      id: '5',
      emoji: '😴',
      title: 'Dormir antes das 23h por 5 dias',
      description: 'Regule seu ciclo circadiano para melhorar a estabilidade emocional.',
      xp: 150,
      progress: 0.8,
      category: 'Rotina',
      isCompleted: false,
    ),
  ];

  void _claimXp(String id, int xpReward) {
    setState(() {
      final index = _dailyMissions.indexWhere((m) => m.id == id);
      if (index != -1) {
        _dailyMissions[index] = _dailyMissions[index].copyWith(isClaimed: true);
      } else {
        final wIndex = _weeklyMissions.indexWhere((m) => m.id == id);
        if (wIndex != -1) {
          _weeklyMissions[wIndex] = _weeklyMissions[wIndex].copyWith(isClaimed: true);
        }
      }
    });
    ref.read(userProfileNotifierProvider.notifier).addXp(xpReward);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('XP resgatado com sucesso! 🎉 +$xpReward XP'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text(
          'Missões e Hábitos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: AppColors.accent),
            onPressed: () => context.push('/achievements'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats card
            _buildStatsCard(profile),
            const SizedBox(height: AppSpacing.lg),

            // Daily Title
            const Text(
              'Missões Diárias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._dailyMissions.map((m) => _buildMissionItem(m)).toList(),

            const SizedBox(height: AppSpacing.lg),

            // Weekly Title
            const Text(
              'Desafios Semanais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._weeklyMissions.map((m) => _buildMissionItem(m)).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile? profile) {
    final String levelLabel = profile?.level.label ?? 'Sementinha';
    final String levelEmoji = profile?.level.emoji ?? '🌱';
    final int levelNum = (LevelType.values.indexOf(profile?.level ?? LevelType.seedling)) + 1;
    final int totalXp = profile?.totalXp ?? 0;

    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E1A4E), Color(0xFF1E1E35)],
      ),
      child: Row(
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$totalXp XP',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildMissionItem(_MissionModel mission) {
    final bool canClaim = mission.progress >= 1.0 && !mission.isClaimed;

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
                    color: AppColors.glass,
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
                          Text(
                            mission.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: mission.isClaimed
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration:
                                  mission.isClaimed ? TextDecoration.lineThrough : null,
                            ),
                          ),
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 6.0,
                    percent: mission.progress,
                    barRadius: const Radius.circular(3),
                    progressColor: AppColors.primary,
                    backgroundColor: AppColors.glass,
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
                if (mission.isClaimed)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 16),
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
                    onPressed: () => _claimXp(mission.id, mission.xp),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _MissionModel {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int xp;
  final double progress;
  final String category;
  final bool isCompleted;
  final bool isClaimed;

  _MissionModel({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.xp,
    required this.progress,
    required this.category,
    required this.isCompleted,
    this.isClaimed = false,
  });

  _MissionModel copyWith({
    bool? isClaimed,
  }) {
    return _MissionModel(
      id: id,
      emoji: emoji,
      title: title,
      description: description,
      xp: xp,
      progress: progress,
      category: category,
      isCompleted: isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
