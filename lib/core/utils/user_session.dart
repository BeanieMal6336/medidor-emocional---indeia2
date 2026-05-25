import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/mood_tracker/providers/mood_provider.dart';
import '../../features/gamification/providers/missions_provider.dart';

/// ID do usuário ativo — reage a login, cadastro e modo offline.
final activeUserIdProvider = Provider<String>((ref) {
  ref.watch(authNotifierProvider);
  final supabaseUser = ref.watch(currentUserProvider);
  if (supabaseUser != null) return supabaseUser.id;
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  return settingsBox.get('current_offline_user_id', defaultValue: 'local_user') as String;
});

String resolveCurrentUserId() {
  final supabaseUser = Supabase.instance.client.auth.currentUser;
  if (supabaseUser != null) return supabaseUser.id;
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  return settingsBox.get('current_offline_user_id', defaultValue: 'local_user') as String;
}

String resolveCurrentUserName() {
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  return settingsBox.get('current_offline_user_name', defaultValue: '') as String;
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

/// Ativa a sessão do usuário recém-criado ou logado — sem reiniciar o app.
Future<void> activateUserSession(
  Ref ref, {
  required String userId,
  required String email,
  required String name,
  required bool offlineMode,
  bool isNewUser = false,
}) async {
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  final userBox = Hive.box(AppConstants.hiveBoxUser);
  await settingsBox.put('current_offline_user_id', userId);
  await settingsBox.put('current_offline_user_email', email);
  await settingsBox.put('current_offline_user_name', name);
  await settingsBox.put('offline_mode', offlineMode);
  if (isNewUser) {
    await clearUserScopedData(userId);
    final freshProfile = {
      'id': userId,
      'email': email,
      'name': name,
      'total_xp': 0,
      'current_streak': 0,
      'longest_streak': 0,
      'created_at': DateTime.now().toIso8601String(),
      'is_onboarding_done': true,
    };
    await userBox.put(userId, jsonEncode(freshProfile));
  } else {
    final raw = userBox.get(userId);
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw as String));
        map['name'] = name;
        map['email'] = email;
        await userBox.put(userId, jsonEncode(map));
      } catch (_) {}
    } else {
      await userBox.put(
        userId,
        jsonEncode({
          'id': userId,
          'email': email,
          'name': name,
          'total_xp': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'created_at': DateTime.now().toIso8601String(),
          'is_onboarding_done': true,
        }),
      );
    }
  }
  invalidateUserScopedProviders(ref);
}

void invalidateUserScopedProviders(Ref ref) {
  ref.invalidate(activeUserIdProvider);
  ref.invalidate(userProfileNotifierProvider);
  ref.invalidate(moodNotifierProvider);
  ref.invalidate(missionsProvider);
}
