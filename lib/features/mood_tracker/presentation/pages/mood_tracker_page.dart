import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/emotion_chip.dart';
import '../../../../core/domain/enums/emotion_type.dart';
import '../../../../core/domain/entities/emotion.dart';
import '../../providers/mood_provider.dart';
import '../../../gamification/providers/missions_provider.dart';

class MoodTrackerPage extends ConsumerStatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  ConsumerState<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends ConsumerState<MoodTrackerPage> {
  int _step = 0;
  int _overallMood = 5;
  final Set<EmotionType> _selectedEmotions = {};
  final Map<EmotionType, int> _emotionIntensity = {};
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedSymptoms = {};
  bool _isSaving = false;

  static const _triggers = [
    '💼 Trabalho', '👨‍👩‍👧 Família', '💕 Relacionamento',
    '💰 Dinheiro', '🏥 Saúde', '😴 Sono', '🍔 Alimentação',
    '📱 Redes sociais', '🔇 Solidão', '🎯 Metas',
  ];

  static const _symptoms = [
    '💓 Coração acelerado', '😮‍💨 Falta de ar', '🤢 Náusea',
    '😰 Sudorese', '😤 Tensão muscular', '🧠 Pensamentos rápidos',
    '😴 Cansaço', '🍽️ Sem apetite', '😣 Dor de cabeça',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final emotions = _selectedEmotions.map((type) {
        final intensity = _emotionIntensity[type] ?? 5;
        return Emotion(type: type, intensity: intensity);
      }).toList();

      await ref.read(moodNotifierProvider.notifier).addEntry(
            overallMood: _overallMood,
            emotions: emotions,
            note: _noteController.text.trim(),
            triggers: _selectedTriggers.toList(),
            physicalSymptoms: _selectedSymptoms.toList(),
          );

      // Conectar registro com a missão de registro de humor diário e semanal
      await ref.read(missionsProvider.notifier).onMoodRegistered();

      HapticFeedback.heavyImpact();
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar registro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        xpEarned: 10 + (_selectedEmotions.length * 2),
        onContinue: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Passo ${_step + 1} de 4',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Step indicator dots
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Row(
              children: List.generate(4, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _step == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _step >= i ? AppColors.primary : AppColors.glass,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              )),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: _buildStep(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepOverallMood(
          key: const ValueKey(0),
          value: _overallMood,
          onChanged: (v) => setState(() => _overallMood = v),
        );
      case 1:
        return _StepEmotions(
          key: const ValueKey(1),
          selected: _selectedEmotions,
          intensities: _emotionIntensity,
          onToggle: (e) {
            setState(() {
              if (_selectedEmotions.contains(e)) {
                _selectedEmotions.remove(e);
                _emotionIntensity.remove(e);
              } else {
                _selectedEmotions.add(e);
                _emotionIntensity[e] = 5;
              }
            });
          },
          onIntensityChanged: (e, v) =>
              setState(() => _emotionIntensity[e] = v),
        );
      case 2:
        return _StepTriggersSymptoms(
          key: const ValueKey(2),
          triggers: _triggers,
          symptoms: _symptoms,
          selectedTriggers: _selectedTriggers,
          selectedSymptoms: _selectedSymptoms,
          onTriggerToggle: (t) => setState(() =>
              _selectedTriggers.contains(t)
                  ? _selectedTriggers.remove(t)
                  : _selectedTriggers.add(t)),
          onSymptomToggle: (s) => setState(() =>
              _selectedSymptoms.contains(s)
                  ? _selectedSymptoms.remove(s)
                  : _selectedSymptoms.add(s)),
        );
      case 3:
        return _StepNote(
          key: const ValueKey(3),
          controller: _noteController,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            GestureDetector(
              onTap: () => setState(() => _step--),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: GradientButton(
              label: _step == 3 ? 'Salvar registro ✨' : 'Próximo',
              isLoading: _isSaving,
              onPressed: _step == 3
                  ? _save
                  : () => setState(() => _step++),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Overall Mood ──────────────────────────────────
class _StepOverallMood extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StepOverallMood({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String get _moodEmoji {
    if (value <= 2) return '😭';
    if (value <= 4) return '😔';
    if (value <= 6) return '😐';
    if (value <= 8) return '🙂';
    return '😄';
  }

  String get _moodLabel {
    if (value <= 2) return 'Péssimo';
    if (value <= 4) return 'Ruim';
    if (value <= 6) return 'Ok';
    if (value <= 8) return 'Bem';
    return 'Ótimo!';
  }

  Color get _moodColor {
    if (value <= 2) return AppColors.emotionSadness;
    if (value <= 4) return AppColors.emotionAnxiety;
    if (value <= 6) return AppColors.accent;
    if (value <= 8) return AppColors.emotionHope;
    return AppColors.emotionJoy;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Como está seu\nhumor agora?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: AppSpacing.xxl),
          // Big emoji
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _moodEmoji,
              key: ValueKey(value),
              style: const TextStyle(fontSize: 96),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _moodColor,
            ),
            child: Text(_moodLabel),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _moodColor,
              inactiveTrackColor: AppColors.glass,
              thumbColor: _moodColor,
              overlayColor: _moodColor.withOpacity(0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v.round());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('10', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Value display
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Intensidade: ',
                    style: TextStyle(color: AppColors.textMuted)),
                Text(
                  '$value/10',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _moodColor,
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

// ── Step 2: Emotions ──────────────────────────────────────
class _StepEmotions extends StatelessWidget {
  final Set<EmotionType> selected;
  final Map<EmotionType, int> intensities;
  final ValueChanged<EmotionType> onToggle;
  final void Function(EmotionType, int) onIntensityChanged;

  const _StepEmotions({
    super.key,
    required this.selected,
    required this.intensities,
    required this.onToggle,
    required this.onIntensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quais emoções\nvocê está sentindo?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Selecione tudo que se encaixa — sem julgamentos.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: EmotionType.values.map((e) => EmotionChip(
              emotion: e,
              isSelected: selected.contains(e),
              onTap: () => onToggle(e),
            )).toList(),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Ajuste a intensidade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...selected.map((e) => _IntensityRow(
              emotion: e,
              value: intensities[e] ?? 5,
              onChanged: (v) => onIntensityChanged(e, v),
            )),
          ],
        ],
      ),
    );
  }
}

class _IntensityRow extends StatelessWidget {
  final EmotionType emotion;
  final int value;
  final ValueChanged<int> onChanged;

  const _IntensityRow({
    required this.emotion,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(emotion.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        emotion.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$value/10',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v.round());
                    },
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

// ── Step 3: Triggers & Symptoms ───────────────────────────
class _StepTriggersSymptoms extends StatelessWidget {
  final List<String> triggers;
  final List<String> symptoms;
  final Set<String> selectedTriggers;
  final Set<String> selectedSymptoms;
  final ValueChanged<String> onTriggerToggle;
  final ValueChanged<String> onSymptomToggle;

  const _StepTriggersSymptoms({
    super.key,
    required this.triggers,
    required this.symptoms,
    required this.selectedTriggers,
    required this.selectedSymptoms,
    required this.onTriggerToggle,
    required this.onSymptomToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O que influenciou\nsua emoção?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xl),
          const Text('Gatilhos', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
          )),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: triggers.map((t) => _TagChip(
              label: t,
              isSelected: selectedTriggers.contains(t),
              color: AppColors.primary,
              onTap: () => onTriggerToggle(t),
            )).toList(),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xl),
          const Text('Sintomas físicos', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
          )),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: symptoms.map((s) => _TagChip(
              label: s,
              isSelected: selectedSymptoms.contains(s),
              color: AppColors.secondary,
              onTap: () => onSymptomToggle(s),
            )).toList(),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? color : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Step 4: Note ──────────────────────────────────────────
class _StepNote extends StatelessWidget {
  final TextEditingController controller;

  const _StepNote({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quer escrever\nalgo mais?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Opcional — um espaço seguro só seu. 🔒',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'O que está em sua mente agora? Pode soltar tudo aqui...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ).animate(delay: 200.ms).fadeIn(),
          ),
        ],
      ),
    );
  }
}

// ── Success Dialog ────────────────────────────────────────
class _SuccessDialog extends StatelessWidget {
  final int xpEarned;
  final VoidCallback onContinue;

  const _SuccessDialog({required this.xpEarned, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderRadius: AppSpacing.radiusXl,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat(period: 2.seconds))
                .shake(hz: 2, offset: const Offset(0, -2)),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Registro salvo!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Obrigado por cuidar da sua mente hoje. 💜',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '+$xpEarned XP ganhos! ⚡',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(label: 'Continuar', onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}
