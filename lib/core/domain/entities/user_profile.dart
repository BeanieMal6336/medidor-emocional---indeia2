import '../enums/level_type.dart';
import '../enums/subscription_type.dart';

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime? lastCheckIn;
  final bool notificationsEnabled;
  final String? reminderTime;
  final bool biometricEnabled;
  final bool isOnboardingDone;
  final SubscriptionType subscription;
  final DateTime? subscriptionExpiresAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.lastCheckIn,
    this.notificationsEnabled = true,
    this.reminderTime,
    this.biometricEnabled = false,
    this.isOnboardingDone = false,
    this.subscription = SubscriptionType.free,
    this.subscriptionExpiresAt,
  });

  LevelType get level => LevelType.fromXp(totalXp);

  int get xpToNextLevel {
    final next = LevelType.values
        .skipWhile((l) => l != level)
        .skip(1)
        .firstOrNull;
    return next == null ? 0 : next.xpRequired - totalXp;
  }

  double get levelProgress {
    final current = level;
    final next = LevelType.values
        .skipWhile((l) => l != current)
        .skip(1)
        .firstOrNull;
    if (next == null) return 1.0;
    final range = next.xpRequired - current.xpRequired;
    final progress = totalXp - current.xpRequired;
    return (progress / range).clamp(0.0, 1.0);
  }

  String get displayName => name ?? email.split('@').first;

  bool get isPremium => subscription.isPremium;
  bool get isGold    => subscription.isGold;
  bool get isSilver  => subscription.isSilver;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatar_url': avatarUrl,
    'total_xp': totalXp,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'created_at': createdAt.toIso8601String(),
    'last_check_in': lastCheckIn?.toIso8601String(),
    'notifications_enabled': notificationsEnabled,
    'reminder_time': reminderTime,
    'biometric_enabled': biometricEnabled,
    'is_onboarding_done': isOnboardingDone,
    'subscription': subscription.toJson(),
    'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    totalXp: json['total_xp'] as int? ?? 0,
    currentStreak: json['current_streak'] as int? ?? 0,
    longestStreak: json['longest_streak'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastCheckIn: json['last_check_in'] != null
        ? DateTime.parse(json['last_check_in'] as String)
        : null,
    notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    reminderTime: json['reminder_time'] as String?,
    biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    isOnboardingDone: json['is_onboarding_done'] as bool? ?? false,
    subscription: SubscriptionType.fromJson(json['subscription'] as String?),
    subscriptionExpiresAt: json['subscription_expires_at'] != null
        ? DateTime.tryParse(json['subscription_expires_at'] as String)
        : null,
  );

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    DateTime? lastCheckIn,
    bool? notificationsEnabled,
    String? reminderTime,
    bool? biometricEnabled,
    bool? isOnboardingDone,
    SubscriptionType? subscription,
    DateTime? subscriptionExpiresAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    totalXp: totalXp ?? this.totalXp,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    createdAt: createdAt ?? this.createdAt,
    lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    reminderTime: reminderTime ?? this.reminderTime,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
    subscription: subscription ?? this.subscription,
    subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
  );
}
