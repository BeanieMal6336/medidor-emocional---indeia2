import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/mood_tracker/providers/mood_provider.dart';
import '../../features/gamification/providers/missions_provider.dart';
import '../../features/ai_companion/providers/mindo_chat_provider.dart';

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
  // Limpa chat legado (Hive antigo)
  try {
    final chatBox = await Hive.openBox('mindo_chat_box');
    await chatBox.delete('messages_$userId');
    await chatBox.delete('state_$userId');
  } catch (_) {}

  // Limpa conversas do novo banco (sessões + mensagens)
  try {
    final conversationsBox = await Hive.openBox(AppConstants.hiveBoxMindoConversations);
    final convKeys = conversationsBox.keys
        .where((k) => k.toString().startsWith('conv_${userId}_'))
        .toList();
    for (final k in convKeys) {
      await conversationsBox.delete(k);
    }
  } catch (_) {}
  try {
    final messagesBox = await Hive.openBox(AppConstants.hiveBoxMindoMessages);
    final msgKeys = messagesBox.keys
        .where((k) => k.toString().startsWith('msg_${userId}_'))
        .toList();
    for (final k in msgKeys) {
      await messagesBox.delete(k);
    }
  } catch (_) {}

  // Limpa missões
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

/// Migra os dados salvos localmente sob um ID de usuário (ex: convidado) para outro ID de usuário (ex: conta criada/logada)
Future<void> migrateUserScopedData(String fromUserId, String toUserId) async {
  if (fromUserId == toUserId) return;

  // 1. Migrar Perfil de Usuário
  try {
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    final rawProfile = userBox.get(fromUserId);
    if (rawProfile != null) {
      final map = Map<String, dynamic>.from(jsonDecode(rawProfile as String));
      map['id'] = toUserId;
      await userBox.put(toUserId, jsonEncode(map));
      await userBox.delete(fromUserId);
    }
  } catch (_) {}

  // 2. Migrar Registros de Humor
  try {
    final moodsBox = Hive.box(AppConstants.hiveBoxMoods);
    for (var key in moodsBox.keys.toList()) {
      final cachedString = moodsBox.get(key) as String?;
      if (cachedString != null) {
        final map = Map<String, dynamic>.from(jsonDecode(cachedString));
        if (map['userId'] == fromUserId) {
          map['userId'] = toUserId;
          await moodsBox.put(key, jsonEncode(map));
        }
      }
    }
  } catch (_) {}

  // 3. Migrar Conversas do Mindo
  try {
    final conversationsBox = Hive.box(AppConstants.hiveBoxMindoConversations);
    final convKeys = conversationsBox.keys
        .where((k) => k.toString().startsWith('conv_${fromUserId}_'))
        .toList();
    for (final k in convKeys) {
      final raw = conversationsBox.get(k) as String?;
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        map['userId'] = toUserId;
        final newKey = k.toString().replaceFirst('conv_${fromUserId}_', 'conv_${toUserId}_');
        await conversationsBox.put(newKey, jsonEncode(map));
        await conversationsBox.delete(k);
      }
    }
  } catch (_) {}

  // 4. Migrar Mensagens do Mindo
  try {
    final messagesBox = Hive.box(AppConstants.hiveBoxMindoMessages);
    final msgKeys = messagesBox.keys
        .where((k) => k.toString().startsWith('msg_${fromUserId}_'))
        .toList();
    for (final k in msgKeys) {
      final raw = messagesBox.get(k) as String?;
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        final newKey = k.toString().replaceFirst('msg_${fromUserId}_', 'msg_${toUserId}_');
        await messagesBox.put(newKey, jsonEncode(map));
        await messagesBox.delete(k);
      }
    }
  } catch (_) {}

  // 5. Migrar Missões
  try {
    final missionsBox = Hive.box('missions_box');
    final keys = missionsBox.keys
        .where((k) => k.toString().startsWith(fromUserId))
        .toList();
    for (final k in keys) {
      final raw = missionsBox.get(k);
      if (raw != null) {
        final newKey = k.toString().replaceFirst(fromUserId, toUserId);
        await missionsBox.put(newKey, raw);
        await missionsBox.delete(k);
      }
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
  final previousId = settingsBox.get('current_offline_user_id') as String?;

  await settingsBox.put('current_offline_user_id', userId);
  await settingsBox.put('current_offline_user_email', email);
  await settingsBox.put('current_offline_user_name', name);
  await settingsBox.put('offline_mode', offlineMode);

  bool wasMigrated = false;
  if (previousId != null && previousId != userId) {
    if (previousId == 'local_user' || previousId.startsWith('local_') || previousId.startsWith('google_')) {
      await migrateUserScopedData(previousId, userId);
      wasMigrated = true;
    }
  }

  if (isNewUser) {
    if (!wasMigrated) {
      await clearUserScopedData(userId);
    }
    final raw = userBox.get(userId);
    if (raw == null) {
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
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw as String));
        map['name'] = name;
        map['email'] = email;
        await userBox.put(userId, jsonEncode(map));
      } catch (_) {}
    }
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
  // Invalida providers de conversas do Mindo ao trocar de usuário
  ref.invalidate(mindoConversationsProvider);
  ref.invalidate(activeConversationIdProvider);
}
