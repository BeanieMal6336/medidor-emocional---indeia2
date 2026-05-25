import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/domain/entities/emotion_entry.dart';
import '../../../../core/domain/enums/emotion_type.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class EmotionalMapPage extends ConsumerStatefulWidget {
  const EmotionalMapPage({super.key});

  @override
  ConsumerState<EmotionalMapPage> createState() => _EmotionalMapPageState();
}

class _EmotionalMapPageState extends ConsumerState<EmotionalMapPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(moodNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Mapa Emocional'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Semana'),
            Tab(text: 'Mês'),
            Tab(text: 'Padrões'),
          ],
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Erro: $e')),
        data: (entries) => TabBarView(
          controller: _tabController,
          children: [
            _WeekView(entries: entries),
            _MonthView(entries: entries),
            _PatternsView(entries: entries),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────
Color _moodColor(double mood) {
  if (mood <= 3) return AppColors.emotionSadness;
  if (mood <= 5) return AppColors.accent;
  if (mood <= 7) return AppColors.emotionHope;
  return AppColors.emotionJoy;
}

String _moodEmoji(double mood) {
  if (mood <= 3) return '😢';
  if (mood <= 5) return '😔';
  if (mood <= 7) return '🙂';
  return '😄';
}

// ── Week View ─────────────────────────────────────────────
class _WeekView extends StatelessWidget {
  final List<EmotionEntry> entries;
  const _WeekView({required this.entries});

  List<EmotionEntry> get _lastWeekEntries {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return entries.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekEntries = _lastWeekEntries;

    // Count emotion frequencies
    final emotionCounts = <EmotionType, int>{};
    for (final entry in weekEntries) {
      for (final emo in entry.emotions) {
        emotionCounts[emo.type] = (emotionCounts[emo.type] ?? 0) + 1;
      }
    }

    // Radar chart uses top 6 positive/notable emotions
    final radarEmotions = [
      EmotionType.joy,
      EmotionType.calm,
      EmotionType.hope,
      EmotionType.motivation,
      EmotionType.love,
      EmotionType.surprise,
    ];
    final maxCount = emotionCounts.values.isEmpty
        ? 1
        : emotionCounts.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Emotion radar chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emoções desta semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 220,
                  child: RadarChart(
                    RadarChartData(
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                      gridBorderData: const BorderSide(
                        color: AppColors.glassBorder,
                        width: 0.5,
                      ),
                      tickBorderData: const BorderSide(color: Colors.transparent),
                      ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                      titleTextStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      getTitle: (i, angle) {
                        return RadarChartTitle(text: radarEmotions[i % radarEmotions.length].label);
                      },
                      dataSets: [
                        RadarDataSet(
                          fillColor: AppColors.primary.withOpacity(0.2),
                          borderColor: AppColors.primary,
                          borderWidth: 2,
                          entryRadius: 4,
                          dataEntries: radarEmotions.map((type) {
                            final count = emotionCounts[type] ?? 0;
                            final normalized = maxCount > 0 ? (count / maxCount) * 10 : 0.0;
                            return RadarEntry(value: normalized);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (weekEntries.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Registre emoções para ver seu radar 🧭',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: AppSpacing.md),
          // Daily breakdown
          _DailyBreakdown(entries: weekEntries),
        ],
      ),
    );
  }
}

class _DailyBreakdown extends StatelessWidget {
  final List<EmotionEntry> entries;
  const _DailyBreakdown({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    final dayData = days.map((date) {
      final dayEntries = entries.where((e) {
        return e.createdAt.year == date.year &&
            e.createdAt.month == date.month &&
            e.createdAt.day == date.day;
      }).toList();

      double mood = 0;
      if (dayEntries.isNotEmpty) {
        mood = dayEntries.fold(0, (sum, e) => sum + e.overallMood) / dayEntries.length;
      }
      return mood;
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dia a dia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final mood = dayData[i];
              final weekday = days[i].weekday;
              final label = labels[weekday - 1];
              return _DayBar(mood: mood, day: label);
            }),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }
}

class _DayBar extends StatelessWidget {
  final double mood;
  final String day;
  const _DayBar({required this.mood, required this.day});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          mood > 0 ? _moodEmoji(mood) : '⬜',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: mood > 0 ? 80 * (mood / 10) : 0,
              decoration: BoxDecoration(
                color: mood > 0 ? _moodColor(mood) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Month View ────────────────────────────────────────────
class _MonthView extends StatelessWidget {
  final List<EmotionEntry> entries;
  const _MonthView({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(now);
    final title = monthLabel[0].toUpperCase() + monthLabel.substring(1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final monthEntries = entries
        .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
        .toList();
    final daysWithData = <int>{};
    final dayMoods = <int, double>{};
    for (final e in monthEntries) {
      final d = e.createdAt.day;
      daysWithData.add(d);
      dayMoods[d] = ((dayMoods[d] ?? 0) + e.overallMood);
    }
    for (final d in dayMoods.keys.toList()) {
      final count = monthEntries.where((e) => e.createdAt.day == d).length;
      if (count > 0) dayMoods[d] = dayMoods[d]! / count;
    }
    final avgMood = monthEntries.isEmpty
        ? 0.0
        : monthEntries.fold<double>(0, (s, e) => s + e.overallMood) / monthEntries.length;
    final progress = daysWithData.length / daysInMonth;
    if (monthEntries.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            _MonthHeader(title: title, progress: 0, daysLogged: 0, daysInMonth: daysInMonth),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Seu calendário emocional está vazio',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Cada dia que você registra o humor aparece aqui com cor e emoji. '
                    'Quanto mais dias, mais claro fica seu padrão mensal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _MonthLegend(),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthHeader(
            title: title,
            progress: progress,
            daysLogged: daysWithData.length,
            daysInMonth: daysInMonth,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '📈',
                  label: 'Média do mês',
                  value: avgMood.toStringAsFixed(1),
                  color: AppColors.emotionHope,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  emoji: '✍️',
                  label: 'Dias registrados',
                  value: '${daysWithData.length}/$daysInMonth',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendário do mês',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toque mentalmente em cada dia: cores = seu humor médio naquele dia.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                _HeatmapGrid(entries: monthEntries, month: now),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Resumo por dia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(daysInMonth, (i) {
            final day = i + 1;
            final mood = dayMoods[day];
            final date = DateTime(now.year, now.month, day);
            final weekday = DateFormat('EEE', 'pt_BR').format(date);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MonthDayRow(
                day: day,
                weekday: weekday,
                mood: mood,
                hasData: mood != null,
              ),
            );
          }).reversed,
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String title;
  final double progress;
  final int daysLogged;
  final int daysInMonth;
  const _MonthHeader({
    required this.title,
    required this.progress,
    required this.daysLogged,
    required this.daysInMonth,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            daysLogged == 0
                ? 'Nenhum registro ainda neste mês'
                : 'Você registrou $daysLogged de $daysInMonth dias (${(progress * 100).round()}%)',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.glass,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthLegend extends StatelessWidget {
  const _MonthLegend();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: const [
        _HeatmapLegend(color: AppColors.glass, label: 'Sem registro'),
        _HeatmapLegend(color: Color(0x996B7FD7), label: 'Difícil'),
        _HeatmapLegend(color: Color(0x99F5A623), label: 'Ok'),
        _HeatmapLegend(color: Color(0x994CAF50), label: 'Bem'),
        _HeatmapLegend(color: Color(0xCC66BB6A), label: 'Ótimo'),
      ],
    );
  }
}

class _MonthDayRow extends StatelessWidget {
  final int day;
  final String weekday;
  final double? mood;
  final bool hasData;
  const _MonthDayRow({
    required this.day,
    required this.weekday,
    required this.mood,
    required this.hasData,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasData ? _moodColor(mood!) : AppColors.glass,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                hasData ? _moodEmoji(mood!) : '·',
                style: TextStyle(
                  fontSize: hasData ? 20 : 18,
                  color: hasData ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dia $day',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  weekday,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            hasData ? '${mood!.toStringAsFixed(1)}/10' : 'Sem dado',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: hasData ? _moodColor(mood!) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<EmotionEntry> entries;
  final DateTime month;
  const _HeatmapGrid({required this.entries, required this.month});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDay = DateTime(month.year, month.month, 1);
    // Weekday: 1=Mon..7=Sun. We want Sunday=0..Saturday=6 grid
    int startOffset = firstDay.weekday % 7; // Sun=0

    Color moodColor(double? mood) {
      if (mood == null) return AppColors.glass;
      if (mood <= 3) return AppColors.emotionSadness.withOpacity(0.6);
      if (mood <= 5) return AppColors.accent.withOpacity(0.5);
      if (mood <= 7) return AppColors.emotionHope.withOpacity(0.6);
      return AppColors.emotionJoy.withOpacity(0.8);
    }

    // Build per-day averages
    final Map<int, double> dayAverages = {};
    for (final entry in entries) {
      final day = entry.createdAt.day;
      dayAverages[day] = (dayAverages[day] ?? 0) + entry.overallMood;
    }
    final Map<int, int> dayCounts = {};
    for (final entry in entries) {
      final day = entry.createdAt.day;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }
    final Map<int, double> dayMoods = {};
    for (final day in dayAverages.keys) {
      dayMoods[day] = dayAverages[day]! / dayCounts[day]!;
    }

    final cells = <Widget>[];
    // Pad empty cells for start of month
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(Container(
        decoration: BoxDecoration(
          color: moodColor(dayMoods[d]),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$d',
            style: TextStyle(
              fontSize: 9,
              color: dayMoods[d] != null ? Colors.white70 : AppColors.textMuted,
            ),
          ),
        ),
      ));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
              .map((d) => Text(d,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  )))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: cells,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HeatmapLegend(color: AppColors.glass, label: 'Vazio'),
            _HeatmapLegend(color: AppColors.emotionSadness.withOpacity(0.6), label: 'Baixo'),
            _HeatmapLegend(color: AppColors.accent.withOpacity(0.5), label: 'Ok'),
            _HeatmapLegend(color: AppColors.emotionHope.withOpacity(0.6), label: 'Bem'),
            _HeatmapLegend(color: AppColors.emotionJoy.withOpacity(0.8), label: 'Ótimo'),
          ],
        ),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _HeatmapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Patterns View ─────────────────────────────────────────
class _PatternsView extends StatelessWidget {
  final List<EmotionEntry> entries;
  const _PatternsView({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'Registre pelo menos 3 dias\npara ver padrões detectados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Detect patterns from real data
    final patterns = _detectPatterns(entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: patterns
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _PatternCard(
                    emoji: e.value.$1,
                    title: e.value.$2,
                    description: e.value.$3,
                    color: e.value.$4,
                  ).animate(delay: (e.key * 100).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                ))
            .toList(),
      ),
    );
  }

  List<(String, String, String, Color)> _detectPatterns(List<EmotionEntry> entries) {
    final patterns = <(String, String, String, Color)>[];

    // Pattern 1: Night hours mood
    final nightEntries = entries.where((e) => e.createdAt.hour >= 21).toList();
    final dayEntries = entries.where((e) => e.createdAt.hour < 18).toList();
    if (nightEntries.length >= 2 && dayEntries.isNotEmpty) {
      final nightAvg = nightEntries.fold(0, (s, e) => s + e.overallMood) / nightEntries.length;
      final dayAvg = dayEntries.fold(0, (s, e) => s + e.overallMood) / dayEntries.length;
      if (nightAvg < dayAvg - 1) {
        patterns.add((
          '🌙',
          'Noites mais difíceis',
          'Seus registros noturnos têm humor ${(dayAvg - nightAvg).toStringAsFixed(1)} pontos abaixo da média diurna. Considere uma rotina noturna relaxante.',
          AppColors.emotionFear,
        ));
      }
    }

    // Pattern 2: Most common trigger
    final triggerCounts = <String, int>{};
    for (final e in entries) {
      for (final t in e.triggers) {
        triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      }
    }
    if (triggerCounts.isNotEmpty) {
      final topTrigger = triggerCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topTrigger.value >= 2) {
        patterns.add((
          '⚡',
          '"${topTrigger.key}" é seu gatilho mais frequente',
          'Esse gatilho apareceu em ${topTrigger.value} dos seus registros. Prestar atenção a ele pode ajudar a se preparar melhor.',
          AppColors.emotionAnxiety,
        ));
      }
    }

    // Pattern 3: Most common emotion
    final emotionCounts = <EmotionType, int>{};
    for (final e in entries) {
      for (final emo in e.emotions) {
        emotionCounts[emo.type] = (emotionCounts[emo.type] ?? 0) + 1;
      }
    }
    if (emotionCounts.isNotEmpty) {
      final topEmo = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final isPositive = [EmotionType.joy, EmotionType.hope, EmotionType.love,
          EmotionType.calm, EmotionType.motivation].contains(topEmo.key);
      patterns.add((
        topEmo.key.emoji,
        '${topEmo.key.label} domina sua semana',
        isPositive
            ? 'Você sentiu ${topEmo.key.label} em ${topEmo.value} registros. Continue cultivando esse estado! 🌱'
            : '${topEmo.key.label} foi recorrente em ${topEmo.value} registros. Que tal explorar o que causa essa emoção?',
        isPositive ? AppColors.emotionHope : AppColors.emotionSadness,
      ));
    }

    // Pattern 4: Consistency
    if (entries.length >= 5) {
      patterns.add((
        '🌟',
        'Consistência em alta!',
        'Você fez ${entries.length} registros emocionais. A constância é o segredo do autoconhecimento. Parabéns! 🎉',
        AppColors.primary,
      ));
    } else if (entries.length >= 2) {
      patterns.add((
        '🚀',
        'Você está começando!',
        'Você tem ${entries.length} registros até agora. Continue registrando diariamente para desbloquear padrões mais ricos.',
        AppColors.accent,
      ));
    }

    return patterns;
  }
}

class _PatternCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _PatternCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
