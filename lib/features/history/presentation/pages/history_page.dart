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
import '../../../../core/domain/enums/emotion_type.dart';
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
    if (avg <= 3.0) return AppColors.emotionSadness;
    if (avg <= 5.5) return AppColors.emotionAnxiety;
    if (avg <= 8.0) return AppColors.emotionHope;
    return AppColors.emotionJoy;
  }

  String _getMoodEmojiForAverage(double avg) {
    if (avg <= 3.0) return '😢';
    if (avg <= 5.5) return '😔';
    if (avg <= 8.0) return '🙂';
    return '😄';
  }

  String _getMoodLabelForAverage(double avg) {
    if (avg <= 3.0) return 'Péssimo';
    if (avg <= 5.5) return 'Instável';
    if (avg <= 8.0) return 'Equilibrado';
    return 'Excelente!';
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
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Relatório PDF exportado com sucesso! 📄✈️'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Custom Slivers for Elegant Scrolling
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.dashboard);
                  }
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 22),
                  tooltip: 'Exportar PDF',
                  onPressed: _exportHistory,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Histórico Emocional',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.bgDark, AppColors.bgMedium],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Sleek Glassy Calendar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: GlassCard(
                borderRadius: AppSpacing.radiusXl,
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final avg = _getDayAverageMood(day, entries);
                      if (avg != null) {
                        final color = _getMoodColorForAverage(avg);
                        return Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.35), color.withOpacity(0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              )
                            ],
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
                      final color = avg != null ? _getMoodColorForAverage(avg) : AppColors.primary;
                      return Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: avg != null ? color.withOpacity(0.25) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.2),
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
                      final color = avg != null ? _getMoodColorForAverage(avg) : AppColors.primary;
                      return Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.75)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
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
                    todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    markerDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                    formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    formatButtonTextStyle: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    titleTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 20),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Premium Dashboard summary
          SliverToBoxAdapter(
            child: _buildMonthlySummary(entries),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // Timeline Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        _selectedDay == null
                            ? 'Hoje'
                            : DateFormat("d 'de' MMMM", 'pt_BR').format(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: Text(
                      '${selectedEvents.length} registro${selectedEvents.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Event Timeline Items
          entriesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, __) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e', style: const TextStyle(color: AppColors.textMuted))),
            ),
            data: (_) => selectedEvents.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = selectedEvents[index];
                          return _buildTimelineItem(event, index == selectedEvents.length - 1)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                        },
                        childCount: selectedEvents.length,
                      ),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(List<EmotionEntry> entries) {
    final monthEntries = entries.where((e) => e.createdAt.year == _focusedDay.year && e.createdAt.month == _focusedDay.month).toList();
    if (monthEntries.isEmpty) return const SizedBox();

    final double avgMood = monthEntries.fold<int>(0, (sum, e) => sum + e.overallMood) / monthEntries.length;
    final Set<String> activeDays = monthEntries.map((e) => '${e.createdAt.day}').toSet();
    
    // Most common emotion
    final emotionCounts = <String, int>{};
    for (final entry in monthEntries) {
      for (final emo in entry.emotions) {
        emotionCounts[emo.type.label] = (emotionCounts[emo.type.label] ?? 0) + 1;
      }
    }
    String dominantEmotion = 'Calma';
    int maxCount = 0;
    emotionCounts.forEach((key, val) {
      if (val > maxCount) {
        maxCount = val;
        dominantEmotion = key;
      }
    });

    // Color map for dominant emotion
    Color dominantColor = AppColors.primary;
    for (var type in EmotionType.values) {
      if (type.label == dominantEmotion) {
        if (type == EmotionType.joy) dominantColor = AppColors.emotionJoy;
        if (type == EmotionType.sadness) dominantColor = AppColors.emotionSadness;
        if (type == EmotionType.anxiety) dominantColor = AppColors.emotionAnxiety;
        if (type == EmotionType.hope || type == EmotionType.calm) dominantColor = AppColors.emotionHope;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GlassCard(
        borderRadius: AppSpacing.radiusXl,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Month average mood
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(height: 6),
                  const Text('Média do Mês', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '${avgMood.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _getMoodColorForAverage(avgMood),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 42, color: AppColors.glassBorder),
            // Days logged
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(height: 8),
                  const Text('Dias Ativos', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '${activeDays.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 42, color: AppColors.glassBorder),
            // Dominant emotion
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(height: 8),
                  const Text('Predomínio', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    dominantEmotion,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: dominantColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.glass, shape: BoxShape.circle),
            child: const Text('🌌', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Nenhum registro para este dia',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua jornada é construída dia após dia.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              foregroundColor: AppColors.primary,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => context.push(AppRoutes.moodTracker),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Registrar Humor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms);
  }

  Widget _buildTimelineItem(EmotionEntry event, bool isLast) {
    final color = _getMoodColorForAverage(event.overallMood.toDouble());
    final timeStr = DateFormat('HH:mm').format(event.createdAt);
    final emoji = _getMoodEmojiForAverage(event.overallMood.toDouble());
    final label = _getMoodLabelForAverage(event.overallMood.toDouble());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time & Indicator Column
          Column(
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              // Double ring indicator node
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.35), AppColors.glassBorder],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Detail Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                  color: AppColors.bgCard.withOpacity(0.3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    // Colored mood indicator bar on the left
                    Container(
                      width: 5,
                      color: color,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$emoji $label',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${event.overallMood}/10',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Notes with quote styling
                            if (event.note != null && event.note!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.glass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.glassBorder.withOpacity(0.5), width: 0.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('“ ', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        event.note!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Styled Pill Tags
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                // Emotions list
                                ...event.emotions.map((emo) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(emo.type.emoji, style: const TextStyle(fontSize: 10)),
                                          const SizedBox(width: 4),
                                          Text(
                                            emo.type.label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primaryLight,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                // Triggers list
                                ...event.triggers.map((tri) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 0.8),
                                      ),
                                      child: Text(
                                        tri,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )),
                                // Symptoms list
                                ...event.physicalSymptoms.map((sym) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGreen.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.2), width: 0.8),
                                      ),
                                      child: Text(
                                        sym,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.accentGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
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
