import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/emotion_entry.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/domain/entities/emotion.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/user_session.dart';

part 'mood_provider.g.dart';

// ── Provedor para gerenciar o perfil do usuário ───────────────────────────
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  late Box _userBox;

  @override
  FutureOr<UserProfile> build() async {
    _userBox = await Hive.openBox(AppConstants.hiveBoxUser);
    
    final localKey = ref.watch(activeUserIdProvider);
    final supabaseUser = ref.watch(currentUserProvider);

    final cachedData = _userBox.get(localKey);
    if (cachedData != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(cachedData as String));
        return UserProfile.fromJson(map);
      } catch (e) {
        // Fallback se JSON corrompido
      }
    }

    // Criar perfil padrão pegando e-mail e nome inseridos no login/cadastro offline
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final offlineEmail = settingsBox.get('current_offline_user_email', defaultValue: 'offline@mindflow.app') as String;
    final offlineName = settingsBox.get('current_offline_user_name', defaultValue: '') as String;
    final resolvedName = (supabaseUser?.userMetadata?['name'] as String?) ??
        (offlineName.isNotEmpty ? offlineName : null);

    final newUser = UserProfile(
      id: localKey,
      email: supabaseUser?.email ?? offlineEmail,
      name: resolvedName,
      createdAt: DateTime.now(),
    );
    await _userBox.put(localKey, jsonEncode(newUser.toJson()));
    return newUser;
  }

  Future<void> addXp(int xp) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updated = currentProfile.copyWith(
      totalXp: currentProfile.totalXp + xp,
    );
    
    state = AsyncValue.data(updated);
    await _userBox.put(updated.id, jsonEncode(updated.toJson()));
    
    // Tentar sincronizar com Supabase se logado e online (background, sem await)
    final supabase = ref.read(supabaseClientProvider);
    final hasUser = ref.read(currentUserProvider) != null;
    if (hasUser) {
      supabase.from('profiles').upsert(updated.toJson()).catchError((e) {
        // Ignora erro de rede, offline-first
      });
    }
  }

  Future<void> updateStreak() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final now = DateTime.now();
    final lastCheck = currentProfile.lastCheckIn;
    
    int newStreak = currentProfile.currentStreak;
    int longest = currentProfile.longestStreak;
    
    if (lastCheck == null) {
      newStreak = 1;
    } else {
      // Normalizar datas para comparar apenas dias
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastCheckDate = DateTime(lastCheck.year, lastCheck.month, lastCheck.day);
      final difference = todayDate.difference(lastCheckDate).inDays;
      
      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1; // quebrou o streak
      }
      // Se a diferença for 0, mantém o mesmo streak (registrou no mesmo dia)
    }
    
    if (newStreak > longest) {
      longest = newStreak;
    }

    final updated = currentProfile.copyWith(
      currentStreak: newStreak,
      longestStreak: longest,
      lastCheckIn: now,
    );

    state = AsyncValue.data(updated);
    await _userBox.put(updated.id, jsonEncode(updated.toJson()));

    // Sincroniza Supabase (background, sem await)
    final supabase = ref.read(supabaseClientProvider);
    final hasUser = ref.read(currentUserProvider) != null;
    if (hasUser) {
      supabase.from('profiles').upsert(updated.toJson()).catchError((e) {
        // ignora
      });
    }
  }
}

// ── Provedor para gerenciar os registros de humor ─────────────────────────
@riverpod
class MoodNotifier extends _$MoodNotifier {
  late Box _moodsBox;

  @override
  FutureOr<List<EmotionEntry>> build() async {
    _moodsBox = await Hive.openBox(AppConstants.hiveBoxMoods);
    
    final userId = ref.watch(activeUserIdProvider);

    // Carrega do Hive
    final List<EmotionEntry> localEntries = [];
    for (var key in _moodsBox.keys) {
      final cachedString = _moodsBox.get(key) as String?;
      if (cachedString != null) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(cachedString));
          final entry = EmotionEntry.fromJson(map);
          if (entry.userId == userId) {
            localEntries.add(entry);
          }
        } catch (e) {
          // ignora se json invalido
        }
      }
    }

    // Ordenar por data decrescente
    localEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final supabaseUser = ref.read(currentUserProvider);
    if (supabaseUser != null) {
      _syncFromSupabase(userId);
    }

    return localEntries;
  }

  Future<void> _syncFromSupabase(String userId) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      final response = await supabase
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<EmotionEntry> remoteEntries = (response as List)
          .map((e) => EmotionEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Salva no Hive localmente as novas do servidor
      for (final entry in remoteEntries) {
        await _moodsBox.put(entry.id, jsonEncode(entry.toJson()));
      }

      state = AsyncValue.data(remoteEntries);
    } catch (e) {
      // Falhou em sincronizar, continua usando local (silencioso)
    }
  }

  Future<void> addEntry({
    required int overallMood,
    required List<Emotion> emotions,
    String? note,
    List<String> triggers = const [],
    List<String> physicalSymptoms = const [],
    List<String> socialContext = const [],
  }) async {
    final userId = ref.read(activeUserIdProvider);
    final entryId = const Uuid().v4();
    final createdAt = DateTime.now();

    // Calcular XP ganho
    final xpEarned = AppConstants.xpPerMoodEntry + (emotions.length * 2);

    final newEntry = EmotionEntry(
      id: entryId,
      userId: userId,
      createdAt: createdAt,
      emotions: emotions,
      note: note,
      triggers: triggers,
      physicalSymptoms: physicalSymptoms,
      socialContext: socialContext,
      overallMood: overallMood,
      xpEarned: xpEarned,
    );

    // Salva localmente no Hive
    await _moodsBox.put(entryId, jsonEncode(newEntry.toJson()));

    // Atualiza estado do Riverpod
    final currentList = state.value ?? [];
    final updatedList = [newEntry, ...currentList];
    state = AsyncValue.data(updatedList);

    // Atualizar XP e Streak do perfil
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    await userProfileNotifier.addXp(xpEarned);
    await userProfileNotifier.updateStreak();

    final supabaseUser = ref.read(currentUserProvider);
    if (supabaseUser != null) {
      final supabase = ref.read(supabaseClientProvider);
      try {
        await supabase.from('mood_entries').insert(newEntry.toJson());
      } catch (_) {
        // ignore offline save error
      }
    }
  }

  Future<void> deleteEntry(String id) async {
    await _moodsBox.delete(id);
    
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((e) => e.id != id).toList());

    final supabaseUser = ref.read(currentUserProvider);
    if (supabaseUser != null) {
      final supabase = ref.read(supabaseClientProvider);
      supabase.from('mood_entries').delete().eq('id', id).catchError((e) {
        // ignore offline delete error
      });
    }
  }
}
