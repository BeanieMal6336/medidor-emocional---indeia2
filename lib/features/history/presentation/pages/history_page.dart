import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/domain/entities/emotion_entry.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../../app/router/app_router.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  double? _getDayAverageMood(DateTime day, List<EmotionEntry> entries) {
    final dayEntries = _getEventsForDay(day, entries);
    if (dayEntries.isEmpty) return null;
    final sum = dayEntries.fold<int>(0, (prev, element) => prev + element.overallMood);
    return sum / dayEntries.length;
  }

  Color _getMoodColorForAverage(double avg) {
    if (avg <= 3.0) return AppColors.emotionSadness.withOpacity(0.85);
    if (avg <= 5.5) return AppColors.emotionAnxiety.withOpacity(0.85);
    if (avg <= 8.0) return AppColors.emotionHope.withOpacity(0.85);
    return AppColors.emotionJoy.withOpacity(0.85);
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<EmotionEntry> _getEventsForDay(DateTime day, List<EmotionEntry> entries) {
    final normalizedKey = DateTime(day.year, day.month, day.day);
    return entries.where((e) {
      final date = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      return isSameDay(date, normalizedKey);
    }).toList();
  }

  void _exportHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Relatório PDF gerado e pronto para exportar! 📄✈️'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(moodNotifierProvider);
    final entries = entriesAsync.value ?? [];
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay, entries);

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
        title: const Text('Histórico Emocional', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'Exportar PDF',
            onPressed: _exportHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sleek Glassy Calendar Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
              child: TableCalendar(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day, entries),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final avg = _getDayAverageMood(day, entries);
                    if (avg != null) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getMoodColorForAverage(avg),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final avg = _getDayAverageMood(day, entries);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: avg != null ? _getMoodColorForAverage(avg) : AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final avg = _getDayAverageMood(day, entries);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: avg != null ? _getMoodColorForAverage(avg) : AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: AppColors.shadowPrimary,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                  weekendTextStyle: TextStyle(color: AppColors.textSecondary),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonTextStyle: TextStyle(color: AppColors.primary, fontSize: 12),
                  titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMonthlySummary(entries),
          const SizedBox(height: AppSpacing.md),

          // Timeline/List header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay == null
                      ? 'Hoje'
                      : DateFormat("d 'de' MMMM", 'pt_BR').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${selectedEvents.length} registro(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Events Timeline
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Erro ao carregar histórico: $e')),
              data: (_) => selectedEvents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      itemCount: selectedEvents.length,
                      itemBuilder: (context, index) {
                        final event = selectedEvents[index];
                        return _buildTimelineItem(event, index == selectedEvents.length - 1)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(List<EmotionEntry> entries) {
    final monthEntries = entries.where((e) => e.createdAt.year == _focusedDay.year && e.createdAt.month == _focusedDay.month).toList();
    if (monthEntries.isEmpty) {
      return const SizedBox();
    }

    final double avgMood = monthEntries.fold<int>(0, (sum, e) => sum + e.overallMood) / monthEntries.length;
    final Set<String> activeDays = monthEntries.map((e) => '${e.createdAt.day}').toSet();
    
    // Encontrar emoção mais frequente
    final emotionCounts = <String, int>{};
    for (final entry in monthEntries) {
      for (final emo in entry.emotions) {
        emotionCounts[emo.type.label] = (emotionCounts[emo.type.label] ?? 0) + 1;
      }
    }
    String dominantEmotion = 'Nenhuma';
    int maxCount = 0;
    emotionCounts.forEach((key, val) {
      if (val > maxCount) {
        maxCount = val;
        dominantEmotion = key;
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Média Mensal', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${avgMood.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _getMoodColorForAverage(avgMood),
                  ),
                ),
              ],
            ),
            Container(width: 1, height: 30, color: AppColors.glassBorder),
            Column(
              children: [
                const Text('Dias Ativos', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${activeDays.length} dias',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(width: 1, height: 30, color: AppColors.glassBorder),
            Column(
              children: [
                const Text('Foco Emocional', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  dominantEmotion,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Nenhum registro para este dia.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.push('/mood-tracker'),
            child: const Text('Registrar agora ✨'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(EmotionEntry event, bool isLast) {
    Color moodColor(int val) {
      if (val <= 3) return AppColors.emotionSadness;
      if (val <= 6) return AppColors.accent;
      if (val <= 8) return AppColors.emotionHope;
      return AppColors.emotionJoy;
    }

    final timeStr = DateFormat('HH:mm').format(event.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time & Indicator column
          Column(
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: moodColor(event.overallMood),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.glassBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Detail Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Humor Geral: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text(
                              '${event.overallMood}/10',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: moodColor(event.overallMood),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (event.note != null && event.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.note!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Emotions & Triggers tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...event.emotions.map((emo) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${emo.type.emoji} ${emo.type.label}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                        ...event.triggers.map((tri) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tri,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                        ...event.physicalSymptoms.map((sym) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sym,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
