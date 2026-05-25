import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/audio_service.dart';

class RelaxationMusicPage extends ConsumerStatefulWidget {
  const RelaxationMusicPage({super.key});

  @override
  ConsumerState<RelaxationMusicPage> createState() => _RelaxationMusicPageState();
}

class _RelaxationMusicPageState extends ConsumerState<RelaxationMusicPage> {
  String _selectedCategory = 'Todos';

  final List<String> _categories = const ['Todos', 'Natureza', 'Música', 'Meditação', 'Ambiente'];

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerStateProvider);
    final audioNotifier = ref.read(audioPlayerStateProvider.notifier);

    // Filtrar faixas
    final filteredTracks = _selectedCategory == 'Todos'
        ? relaxationTracks
        : relaxationTracks.where((t) => t.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Decorativo Premium
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
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
                              'Sons de Cura',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer to balance back button
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Sons Relaxantes',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Acalme sua mente com sons da natureza e frequências de cura.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ).animate(delay: 100.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),

                // Filtro de Categorias
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : AppColors.glass,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(
                                color: isSel ? AppColors.primaryLight : AppColors.glassBorder,
                                width: 1,
                              ),
                              boxShadow: isSel ? AppColors.shadowPrimary : null,
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSel ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

                // Lista de Músicas
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    playerState.currentTrackId != null ? 180 : 40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = filteredTracks[index];
                        final isCurrent = playerState.currentTrackId == track.id;
                        final isPlaying = isCurrent && playerState.isPlaying;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              onTap: () {
                                if (isCurrent) {
                                  audioNotifier.togglePlayPause();
                                } else {
                                  audioNotifier.play(track);
                                }
                              },
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                    color: isCurrent ? AppColors.primary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isPlaying
                                      ? const _EqualizerBars()
                                      : Text(track.emoji, style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              title: Text(
                                track.name,
                                style: TextStyle(
                                  color: isCurrent ? AppColors.primaryLight : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  track.description,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              trailing: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrent ? AppColors.primary : Colors.white.withOpacity(0.05),
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1);
                      },
                      childCount: filteredTracks.length,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini Player Glassmorphic Flutuante no Rodapé
          if (playerState.currentTrackId != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildMiniPlayer(context, playerState, audioNotifier),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    AudioPlayerState playerState,
    AudioStateNotifier audioNotifier,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Track Info
              Text(
                playerState.currentTrackEmoji ?? '🎵',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerState.currentTrackName ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Foco e Relaxamento',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Sleep Timer button
              _buildSleepTimerButton(playerState, audioNotifier),
              const SizedBox(width: AppSpacing.xs),

              // Control buttons
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                onPressed: () => audioNotifier.stop(),
              ),
              GestureDetector(
                onTap: () => audioNotifier.togglePlayPause(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientPrimary,
                  ),
                  child: Icon(
                    playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Volume Slider
          Row(
            children: [
              const Icon(Icons.volume_mute_rounded, color: AppColors.textMuted, size: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.glass,
                    thumbColor: AppColors.primaryLight,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: playerState.volume,
                    onChanged: (vol) => audioNotifier.setVolume(vol),
                  ),
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: AppColors.textMuted, size: 16),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.5, curve: Curves.easeOutBack);
  }

  Widget _buildSleepTimerButton(AudioPlayerState playerState, AudioStateNotifier audioNotifier) {
    return PopupMenuButton<int?>(
      icon: Icon(
        Icons.timer_rounded,
        color: playerState.timerMinutes != null ? AppColors.secondary : Colors.white70,
        size: 20,
      ),
      tooltip: 'Temporizador de Sono',
      color: AppColors.bgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (minutes) {
        if (!mounted) return;
        audioNotifier.setTimer(minutes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              minutes == null
                  ? 'Temporizador cancelado.'
                  : 'O som irá parar em $minutes minutos. 😴',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      itemBuilder: (context) => const [
        PopupMenuItem<int?>(
          value: null,
          child: Text('Desativado', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem<int?>(
          value: 5,
          child: Text('5 minutos', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem<int?>(
          value: 15,
          child: Text('15 minutos', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem<int?>(
          value: 30,
          child: Text('30 minutos', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem<int?>(
          value: 45,
          child: Text('45 minutos', style: TextStyle(color: Colors.white70)),
        ),
        PopupMenuItem<int?>(
          value: 60,
          child: Text('60 minutos', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

// ── Equalizador de Barras Animadas ───────────────────────────────────────────
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars();

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 150)),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: 3.5,
              height: 24 * _animations[index].value,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: AppColors.gradientPrimary,
              ),
            );
          },
        );
      }),
    );
  }
}
