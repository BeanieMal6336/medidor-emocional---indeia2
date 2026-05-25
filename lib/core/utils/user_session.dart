import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/mood_tracker/providers/mood_provider.dart';
import '../../features/gamification/providers/missions_provider.dart';

String resolveCurrentUserId(Ref ref) {
  final supabaseUser = ref.read(currentUserProvider);
  if (supabaseUser != null) return supabaseUser.id;
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  return settingsBox.get('current_offline_user_id', defaultValue: 'local_user') as String;
}

Future<void> clearUserScopedData(String userId) async {
  try {
    final chatBox = await Hive.openBox('mindo_chat_box');
    await chatBox.delete('messages_$userId');
    await chatBox.delete('state_$userId');
  } catch (_) {}
  try {
    final missionsBox = Hive.box('missions_box');
    final keys = missionsBox.keys
        .where((k) => k.toString().startsWith(userId))
        .toList();
    for (final k in keys) {
      await missionsBox.delete(k);
    }
  } catch (_) {}
}

void invalidateUserScopedProviders(Ref ref) {
  ref.invalidate(userProfileNotifierProvider);
  ref.invalidate(moodNotifierProvider);
  ref.invalidate(missionsProvider);
}
