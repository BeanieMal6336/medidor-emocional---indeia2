abstract class AppConstants {
  // ── Supabase ─────────────────────────────────────────────
  // ATENÇÃO: Substitua pelos valores reais do seu projeto Supabase
  static const supabaseUrl = 'https://uxjwkmvojlwyzjbxkqju.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_W5UNvqX1pCk5VRj3ZvPKrA_jaoUAHIN';

  // ── App Info ─────────────────────────────────────────────
  static const appName = 'MindFlow';
  static const appVersion = '1.0.0';
  static const appBuildNumber = 1;

  // ── Gamificação ──────────────────────────────────────────
  static const xpPerMoodEntry = 10;
  static const xpPerMission = 50;
  static const xpPerStreak = 5;
  static const xpPerAiChat = 15;

  // ── Níveis emocionais ────────────────────────────────────
  static const levelLight = 'Leve';
  static const levelModerate = 'Moderado';
  static const levelHigh = 'Alto';
  static const levelCritical = 'Crítico';

  // ── Hive boxes ───────────────────────────────────────────
  static const hiveBoxUser = 'user_box';
  static const hiveBoxMoods = 'moods_box';
  static const hiveBoxSettings = 'settings_box';
  static const hiveBoxCache = 'cache_box';
  static const hiveBoxMindoConversations = 'mindo_conversations_box';
  static const hiveBoxMindoMessages = 'mindo_messages_box';

  // ── Chaves de preferências ───────────────────────────────
  static const prefOnboardingDone = 'onboarding_done';
  static const prefBiometricEnabled = 'biometric_enabled';
  static const prefThemeMode = 'theme_mode';
  static const prefNotifications = 'notifications_enabled';
  static const prefReminderTime = 'reminder_time';

  // ── Limites ──────────────────────────────────────────────
  static const maxEmotionsPerEntry = 5;
  static const maxTriggersPerEntry = 10;
  static const maxAiMessageLength = 2000;
  static const maxNoteLength = 5000;

  // ── IA ───────────────────────────────────────────────────
  static const aiModelClaude = 'claude-3-5-sonnet-20241022';
  static const aiModelGpt4 = 'gpt-4o';
  static const aiMaxTokens = 1024;
  static const aiTemperature = 0.7;
}
