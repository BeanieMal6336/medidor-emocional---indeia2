import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/mood_tracker/presentation/pages/mood_tracker_page.dart';
import '../../features/emotional_map/presentation/pages/emotional_map_page.dart';
import '../../features/ai_companion/presentation/pages/ai_companion_page.dart';
import '../../features/gamification/presentation/pages/missions_page.dart';
import '../../features/gamification/presentation/pages/achievements_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../core/widgets/scaffold_with_nav.dart';
import '../../features/relaxation/presentation/pages/relaxation_music_page.dart';
import '../../features/relaxation/presentation/pages/meditation_page.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.moodTracker,
        builder: (context, state) => const MoodTrackerPage(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.emotionalMap,
            builder: (context, state) => const EmotionalMapPage(),
          ),
          GoRoute(
            path: AppRoutes.missions,
            builder: (context, state) => const MissionsPage(),
          ),
          GoRoute(
            path: AppRoutes.aiCompanion,
            builder: (context, state) => const AiCompanionPage(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.insights,
            builder: (context, state) => const InsightsPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.relaxation,
            builder: (context, state) => const RelaxationMusicPage(),
          ),
          GoRoute(
            path: AppRoutes.meditation,
            builder: (context, state) => const MeditationPage(),
          ),
        ],
      ),
    ],
  );
}

abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const moodTracker = '/mood-tracker';
  static const emotionalMap = '/emotional-map';
  static const aiCompanion = '/ai-companion';
  static const missions = '/missions';
  static const achievements = '/achievements';
  static const history = '/history';
  static const insights = '/insights';
  static const settings = '/settings';
  static const profile = '/profile';
  static const relaxation = '/relaxation';
  static const meditation = '/meditation';
}
