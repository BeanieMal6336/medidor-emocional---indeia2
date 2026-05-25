import '../domain/enums/level_type.dart';
import '../domain/entities/user_profile.dart';

class UserJourneyStats {
  final int daysOnJourney;
  final int moodEntries;
  final int claimedMissions;
  final int xpToNext;
  final double levelProgress;
  final String nextLevelLabel;
  final String insight;
  const UserJourneyStats({
    required this.daysOnJourney,
    required this.moodEntries,
    required this.claimedMissions,
    required this.xpToNext,
    required this.levelProgress,
    required this.nextLevelLabel,
    required this.insight,
  });
}

UserJourneyStats buildJourneyStats({
  required UserProfile profile,
  required int moodEntriesCount,
  required int claimedMissionsCount,
}) {
  final days = DateTime.now().difference(profile.createdAt).inDays + 1;
  final level = profile.level;
  final next = LevelType.values
      .skipWhile((l) => l != level)
      .skip(1)
      .firstOrNull;
  final nextLabel = next?.label ?? 'Máximo';
  String insight;
  if (moodEntriesCount == 0) {
    insight = 'Comece registrando seu humor hoje — isso libera XP e desbloqueia insights.';
  } else if (profile.currentStreak >= 3) {
    insight = 'Sua sequência mostra compromisso real com sua saúde mental.';
  } else if (claimedMissionsCount == 0) {
    insight = 'Complete missões diárias para evoluir nível com ações concretas.';
  } else {
    insight = 'Cada registro e conversa com o Mindo fortalece sua jornada.';
  }
  return UserJourneyStats(
    daysOnJourney: days,
    moodEntries: moodEntriesCount,
    claimedMissions: claimedMissionsCount,
    xpToNext: profile.xpToNextLevel,
    levelProgress: profile.levelProgress,
    nextLevelLabel: nextLabel,
    insight: insight,
  );
}
