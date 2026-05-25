import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/services/audio_service.dart';
import '../../../gamification/providers/missions_provider.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class MeditationPage extends ConsumerStatefulWidget {
  const MeditationPage({super.key});

  @override
  ConsumerState<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends ConsumerState<MeditationPage> with TickerProviderStateMixin {
  bool _isPlaying = false;
  int _secondsLeft = 300; // 5 minutos por padrão
  Timer? _timer;
  String _meditationTitle = '';
  String _breathingText = 'Prepare-se...';
  double _breathScale = 1.0;
  Timer? _breathingCycleTimer;

  // Estado do ciclo de respiração: 0=Inspira, 1=Segura, 2=Expira
  int _breathingState = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _breathingCycleTimer?.cancel();
    super.dispose();
  }

  void _startMeditation(String title, RelaxationTrack soundTrack) {
    setState(() {
      _isPlaying = true;
      _secondsLeft = 300; // 5 minutos
      _meditationTitle = title;
      _breathingText = 'Inspire...';
      _breathScale = 1.6;
    });

    // Tocar áudio de fundo
    ref.read(audioPlayerStateProvider.notifier).play(soundTrack);

    // Iniciar temporizador da sessão
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _completeMeditation();
      }
    });

    // Iniciar ciclo de respiração: 4s inspira (expandir), 4s segura, 4s expira (contrair)
    _breathingState = 0;
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    _breathingCycleTimer?.cancel();

    int duration = 4; // ciclo de 4s
    if (_breathingState == 0) {
      // Inspire
      setState(() {
        _breathingText = 'Inspire lentamente... 🫁';
        _breathScale = 1.6;
      });
    } else if (_breathingState == 1) {
      // Segure
      setState(() {
        _breathingText = 'Segure o ar... 🧘';
        _breathScale = 1.6;
      });
    } else {
      // Expire
      setState(() {
        _breathingText = 'Expire com calma... 🌬️';
        _breathScale = 1.0;
      });
    }

    _breathingCycleTimer = Timer(Duration(seconds: duration), () {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _breathingState = (_breathingState + 1) % 3;
      });
      _runBreathingCycle();
    });
  }

  Future<void> _completeMeditation() async {
    _timer?.cancel();
    _breathingCycleTimer?.cancel();
    
    // Parar música
    ref.read(audioPlayerStateProvider.notifier).stop();

    setState(() {
      _isPlaying = false;
    });

    // Trigger da missão de meditação
    await ref.read(missionsProvider.notifier).onMeditationCompleted();

    // Conceder XP diretamente ao perfil
    await ref.read(userProfileNotifierProvider.notifier).addXp(40);

    HapticFeedback.heavyImpact();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassCard(
            borderRadius: AppSpacing.radiusXl,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧘✨', style: TextStyle(fontSize: 64))
                    .animate(onPlay: (c) => c.repeat(period: 2.seconds))
                    .shake(hz: 2, offset: const Offset(0, -2)),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Sessão Concluída!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Parabéns por dedicar um tempo para silenciar sua mente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: const Text(
                    '+40 XP Ganhos! ⚡',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
                const SizedBox(height: AppSpacing.xl),
                GradientButton(
                  label: 'Voltar ao MindFlow',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _abortMeditation() {
    _timer?.cancel();
    _breathingCycleTimer?.cancel();
    ref.read(audioPlayerStateProvider.notifier).stop();
    setState(() {
      _isPlaying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão cancelada.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return _buildActiveMeditationView();
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Decorativo
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emotionCalm.withOpacity(0.15),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'Meditação Flow',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Jornada de Meditação',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Práticas guiadas de respiração e presença mental para restaurar a paz interior.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.xl),

                  // Respiração Rápida Imersiva
                  const Text(
                    'Escolha uma Jornada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildProgramCard(
                    title: 'Alívio Instantâneo de Ansiedade 🧘',
                    durationText: '5 min',
                    description: 'Acalme a mente acelerada e equilibre seu batimento cardíaco com respiração controlada.',
                    soundName: 'Som: Tigelas Tibetanas',
                    color: AppColors.emotionCalm,
                    onTap: () {
                      final tibetanTrack = relaxationTracks.firstWhere((t) => t.id == 'tibetan');
                      _startMeditation('Alívio de Ansiedade', tibetanTrack);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildProgramCard(
                    title: 'Foco e Clareza Mental 🧠',
                    durationText: '5 min',
                    description: 'Restaure sua capacidade de foco e reduza o ruído mental com esta meditação revigorante.',
                    soundName: 'Som: Spa Relaxante',
                    color: AppColors.primary,
                    onTap: () {
                      final spaTrack = relaxationTracks.firstWhere((t) => t.id == 'spa');
                      _startMeditation('Foco e Clareza', spaTrack);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildProgramCard(
                    title: 'Natureza Imersiva 🌊',
                    durationText: '5 min',
                    description: 'Sinta-se caminhando perto do oceano enquanto harmoniza seus pensamentos com as ondas.',
                    soundName: 'Som: Ondas do Mar',
                    color: AppColors.accentGreen,
                    onTap: () {
                      final oceanTrack = relaxationTracks.firstWhere((t) => t.id == 'ocean');
                      _startMeditation('Natureza Imersiva', oceanTrack);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard({
    required String title,
    required String durationText,
    required String description,
    required String soundName,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      soundName,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        durationText,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Começar Jornada',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActiveMeditationView() {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancelar Meditação?'),
            content: const Text('Deseja realmente cancelar a sessão de meditação?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
            ],
          ),
        );
        if (shouldPop == true) {
          _abortMeditation();
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Stack(
          children: [
            Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 4),
                width: 250 * _breathScale,
                height: 250 * _breathScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emotionCalm.withOpacity(0.4),
                      AppColors.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 4),
                width: 180 * _breathScale,
                height: 180 * _breathScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.emotionCalm.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _meditationTitle.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emotionCalm,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Respiração Consciente',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            shadows: [
                              Shadow(
                                color: AppColors.emotionCalm.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(_breathingText),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgCard.withOpacity(0.8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Center(
                            child: Text(
                              _formatDuration(_secondsLeft),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Feche os olhos e siga o ritmo visual ou sonoro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Cancelar Sessão', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _abortMeditation,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              icon: const Icon(Icons.done_all_rounded),
                              label: const Text('Concluir (Pular)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _completeMeditation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
