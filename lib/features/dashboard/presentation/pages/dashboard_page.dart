import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../app/router/app_router.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../gamification/providers/missions_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.md),
                _MoodCheckInCard(),
                const SizedBox(height: AppSpacing.md),
                const _XpSection(),
                const SizedBox(height: AppSpacing.md),
                const _WeeklyMoodChart(),
                const SizedBox(height: AppSpacing.md),
                _InsightCard(),
                const SizedBox(height: AppSpacing.md),
                const _RelaxationMeditationCard(),
                const SizedBox(height: AppSpacing.md),
                _MissionsPreview(),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final profile = profileAsync.value;
    final streak = profile?.currentStreak ?? 0;
    final name = profile?.displayName ?? 'Viajante';

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A2E), AppColors.bgDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'Olá, $name! ✨',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Streak badge
                      StreakBadge(streak: streak, compact: true),
                      const SizedBox(width: AppSpacing.sm),
                      // Avatar
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('😊', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia ☀️';
    if (hour < 18) return 'Boa tarde 🌤️';
    return 'Boa noite 🌙';
  }
}

// ── Mood Check-in Card ────────────────────────────────────
class _MoodCheckInCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A1A4E), Color(0xFF1E1E35)],
      ),
      onTap: () => context.push(AppRoutes.moodTracker),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Como você está agora?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Text(
                  'Registrar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods
                .map(
                  (m) => _MoodEmoji(emoji: m.$1, label: m.$2),
                )
                .toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1);
  }

  static const _moods = [
    ('😭', 'Péssimo'),
    ('😔', 'Ruim'),
    ('😐', 'Ok'),
    ('🙂', 'Bem'),
    ('😄', 'Ótimo'),
  ];
}

class _MoodEmoji extends StatelessWidget {
  final String emoji;
  final String label;

  const _MoodEmoji({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.moodTracker),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── XP Section ───────────────────────────────────────────
class _XpSection extends ConsumerWidget {
  const _XpSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileNotifierProvider);

    return profileAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, __) => const SizedBox(),
      data: (profile) {
        return GlassCard(
          child: XpBar(
            currentXp: profile.totalXp,
            maxXp: profile.totalXp + profile.xpToNextLevel,
            levelLabel: profile.level.label,
            levelEmoji: profile.level.emoji,
          ),
        );
      },
    );
  }
}

// ── Weekly Mood Chart ────────────────────────────────────
class _WeeklyMoodChart extends ConsumerWidget {
  const _WeeklyMoodChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(moodNotifierProvider);

    return entriesAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, __) => const SizedBox(),
      data: (entries) {
        final now = DateTime.now();
        final spots = <FlSpot>[];
        final weekdayLabels = <String>[];

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          weekdayLabels.add(_getWeekdayAbbreviation(date.weekday));

          final dayEntries = entries.where((e) {
            return e.createdAt.year == date.year &&
                e.createdAt.month == date.month &&
                e.createdAt.day == date.day;
          }).toList();

          double avg = 5.0; // Padrão se não houver registros
          if (dayEntries.isNotEmpty) {
            final sum = dayEntries.fold(0, (sum, e) => sum + e.overallMood);
            avg = sum / dayEntries.length;
          }

          spots.add(FlSpot((6 - i).toDouble(), avg));
        }

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evolução semanal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Últimos 7 dias',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= weekdayLabels.length) return const SizedBox();
                            return Text(
                              weekdayLabels[idx],
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.bgDark,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getWeekdayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'Seg';
      case 2: return 'Ter';
      case 3: return 'Qua';
      case 4: return 'Qui';
      case 5: return 'Sex';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }
}

class _InsightCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(moodNotifierProvider);
    final entries = entriesAsync.value ?? [];
    final profile = ref.watch(userProfileNotifierProvider).value;

    String insightText;
    if (entries.isEmpty) {
      insightText = 'Comece registrando seu humor para receber insights personalizados sobre seu bem-estar emocional. 🌱';
    } else {
      final streak = profile?.currentStreak ?? 0;
      final totalXp = profile?.totalXp ?? 0;
      final now = DateTime.now();
      final todayEntries = entries.where((e) =>
        e.createdAt.year == now.year &&
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day).toList();
      final recentEntries = entries.take(7).toList();

      if (streak >= 7) {
        insightText = '🌟 Incrível! $streak dias de sequência — você está construindo um hábito real de autocuidado!';
      } else if (streak >= 3) {
        insightText = '🔥 $streak dias seguidos! Consistência é a base do bem-estar emocional. Continue assim!';
      } else if (todayEntries.isEmpty) {
        insightText = '⏰ Você ainda não registrou seu humor hoje. Que tal fazer isso agora? São só 2 minutos. 💫';
      } else if (totalXp == 0) {
        insightText = 'Complete sua primeira missão para ganhar XP e subir de nível na sua jornada emocional! ⚡';
      } else if (recentEntries.length >= 3) {
        final avgMood = recentEntries.fold(0, (s, e) => s + e.overallMood) / recentEntries.length;
        if (avgMood >= 7) {
          insightText = 'Seus últimos registros mostram um humor positivo! O que tem contribuído para isso? 🌟';
        } else if (avgMood <= 4) {
          insightText = 'Notei que você está passando por um período mais difícil. Conversar com o Mindo pode ajudar. 💜';
        } else {
          insightText = 'Seus registros mostram uma jornada equilibrada. Continue se observando com gentileza. 🌱';
        }
      } else {
        insightText = 'Continue registrando seu humor para receber insights cada vez mais precisos! 📊';
      }
    }

    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A2E1A), Color(0xFF1E1E35)],
      ),
      onTap: () => context.go(AppRoutes.aiCompanion),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight do Mindo ✨',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Missions Preview ───────────────────────────────────────
class _MissionsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsState = ref.watch(missionsProvider);
    final daily = missionsState.daily.take(3).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Missões de hoje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.missions),
                child: const Text(
                  'Ver todas →',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (missionsState.isLoading)
            const Center(child: SizedBox(height: 60, child: CircularProgressIndicator()))
          else if (daily.isEmpty)
            const Text('Nenhuma missão disponível', style: TextStyle(color: AppColors.textMuted))
          else
            ...daily.map((m) => _MissionTile(mission: m)),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _MissionTile extends StatelessWidget {
  final MissionData mission;
  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: mission.isClaimed
                  ? AppColors.accentGreen.withOpacity(0.15)
                  : AppColors.glass,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(mission.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              mission.title,
              style: TextStyle(
                fontSize: 14,
                color: mission.isClaimed ? AppColors.textMuted : AppColors.textPrimary,
                decoration: mission.isClaimed ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '+${mission.xp} XP',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            mission.isClaimed
                ? Icons.check_circle_rounded
                : mission.progress >= 1.0
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
            color: mission.isClaimed || mission.progress >= 1.0
                ? AppColors.accentGreen
                : AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final BuildContext ctx;
  const _QuickActions(this.ctx);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acesso rápido',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _QuickAction(
              emoji: '🗺️',
              label: 'Mapa\nEmocional',
              color: AppColors.emotionCalm,
              onTap: () => context.go(AppRoutes.emotionalMap),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAction(
              emoji: '📊',
              label: 'Histórico',
              color: AppColors.primary,
              onTap: () => context.go(AppRoutes.history),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAction(
              emoji: '💡',
              label: 'Insights',
              color: AppColors.accent,
              onTap: () => context.go(AppRoutes.insights),
            ),
          ],
        ),
      ],
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Relaxation & Meditation Card ──────────────────────────
class _RelaxationMeditationCard extends StatelessWidget {
  const _RelaxationMeditationCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relaxamento e Presença 🧘✨',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Práticas de meditação e sons da natureza para acalmar a mente.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.meditation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primaryLight, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Text('🧘', style: TextStyle(fontSize: 16)),
                  label: const Text(
                    'Meditação',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.relaxation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.accentGreen, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Text('🎵', style: TextStyle(fontSize: 16)),
                  label: const Text(
                    'Sons de Cura',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
