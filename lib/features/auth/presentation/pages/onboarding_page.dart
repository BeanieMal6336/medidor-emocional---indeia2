import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      emoji: '🧠',
      title: 'Sua mente\nfinalmente faz sentido',
      description:
          'Registre emoções, descubra padrões e entenda o que está acontecendo dentro de você — de um jeito visual, fácil e sem julgamentos.',
      gradient: AppColors.gradientPrimary,
      bg: Color(0xFF1A0A2E),
    ),
    _OnboardingData(
      emoji: '🌊',
      title: 'Navegue pelas\nsuas emoções',
      description:
          'Visualize heatmaps emocionais, detecte gatilhos e acompanhe sua evolução ao longo do tempo com gráficos incríveis.',
      gradient: AppColors.gradientCalm,
      bg: Color(0xFF0A1A2E),
    ),
    _OnboardingData(
      emoji: '🌟',
      title: 'Evolua e\nsuba de nível',
      description:
          'Ganhe XP, complete missões e desbloqueie conquistas enquanto cuida da sua saúde mental. Saúde emocional que vicia do jeito certo.',
      gradient: AppColors.gradientJoy,
      bg: Color(0xFF1A1A0A),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final box = await Hive.openBox(AppConstants.hiveBoxSettings);
      await box.put(AppConstants.prefOnboardingDone, true);
    } catch (_) {}
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage].bg,
      body: Stack(
        children: [
          // Background animated gradient blob
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _pages[_currentPage].gradient,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 3.seconds,
                curve: Curves.easeInOut,
              ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Pular',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) =>
                        _OnboardingSlide(data: _pages[i]),
                  ),
                ),
                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.glass,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      GradientButton(
                        label: _currentPage == _pages.length - 1
                            ? 'Começar agora 🚀'
                            : 'Próximo',
                        onPressed: _next,
                        gradient: _pages[_currentPage].gradient,
                      ),
                    ],
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

class _OnboardingData {
  final String emoji;
  final String title;
  final String description;
  final Gradient gradient;
  final Color bg;

  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
    required this.bg,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in gradient container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: data.gradient,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 64)),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ).animate(delay: 350.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
