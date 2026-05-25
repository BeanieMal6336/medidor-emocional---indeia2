import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/entities/mission.dart';
import '../../../core/domain/enums/mission_status.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../mood_tracker/providers/mood_provider.dart';
import '../../../core/services/sensor_service.dart';

// ── Provider de missões ────────────────────────────────────────────────────
final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>(
  (ref) => MissionsNotifier(ref),
);

class MissionsState {
  final List<MissionData> daily;
  final List<MissionData> weekly;
  final bool isLoading;

  const MissionsState({
    this.daily = const [],
    this.weekly = const [],
    this.isLoading = true,
  });

  MissionsState copyWith({
    List<MissionData>? daily,
    List<MissionData>? weekly,
    bool? isLoading,
  }) =>
      MissionsState(
        daily: daily ?? this.daily,
        weekly: weekly ?? this.weekly,
        isLoading: isLoading ?? this.isLoading,
      );
}

class MissionData {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int xp;
  final double progress;
  final String category;
  final bool isCompleted;
  final bool isClaimed;
  final bool isManual; // missões que o usuário marca manualmente

  const MissionData({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.xp,
    required this.progress,
    required this.category,
    required this.isCompleted,
    required this.isClaimed,
    this.isManual = false,
  });

  MissionData copyWith({
    double? progress,
    bool? isCompleted,
    bool? isClaimed,
  }) =>
      MissionData(
        id: id,
        emoji: emoji,
        title: title,
        description: description,
        xp: xp,
        progress: progress ?? this.progress,
        category: category,
        isCompleted: isCompleted ?? this.isCompleted,
        isClaimed: isClaimed ?? this.isClaimed,
        isManual: isManual,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress': progress,
        'isCompleted': isCompleted,
        'isClaimed': isClaimed,
      };

  static MissionData fromTemplate(
    Map<String, dynamic> template,
    Map<String, dynamic>? savedState,
  ) {
    return MissionData(
      id: template['id'] as String,
      emoji: template['emoji'] as String,
      title: template['title'] as String,
      description: template['description'] as String,
      xp: template['xp'] as int,
      progress: savedState?['progress'] as double? ?? 0.0,
      category: template['category'] as String,
      isCompleted: savedState?['isCompleted'] as bool? ?? false,
      isClaimed: savedState?['isClaimed'] as bool? ?? false,
      isManual: template['isManual'] as bool? ?? false,
    );
  }
}

// Missões diárias — templates
final _dailyTemplates = [
  {
    'id': 'daily_mood',
    'emoji': '🧠',
    'title': 'Registrar seu humor',
    'description': 'Abra o app e registre como você está sentindo hoje.',
    'xp': 30,
    'category': 'Mente',
    'isManual': false,
  },
  {
    'id': 'daily_water',
    'emoji': '💧',
    'title': 'Beber 2L de água',
    'description': 'Mantenha seu corpo hidratado para ajudar na clareza mental.',
    'xp': 20,
    'category': 'Saúde',
    'isManual': true,
  },
  {
    'id': 'daily_walk',
    'emoji': '🚶',
    'title': 'Caminhar 15 minutos',
    'description': 'Uma caminhada leve ajuda a clarear a mente e reduzir o cortisol.',
    'xp': 30,
    'category': 'Corpo',
    'isManual': true,
  },
  {
    'id': 'daily_mindo',
    'emoji': '🤖',
    'title': 'Conversar com o Mindo',
    'description': 'Abra o assistente Mindo e compartilhe como está se sentindo.',
    'xp': 25,
    'category': 'Mente',
    'isManual': false,
  },
  {
    'id': 'daily_journal',
    'emoji': '✍️',
    'title': 'Escrever 3 pensamentos',
    'description': 'Coloque no papel tudo o que está tirando seu foco.',
    'xp': 25,
    'category': 'Mente',
    'isManual': true,
  },
];

// Missões semanais — templates
final _weeklyTemplates = [
  {
    'id': 'weekly_breathing',
    'emoji': '🧘',
    'title': '5 sessões de respiração',
    'description': 'Pratique a respiração consciente guiada com o Mindo.',
    'xp': 100,
    'category': 'Mindfulness',
    'isManual': false,
  },
  {
    'id': 'weekly_sleep',
    'emoji': '😴',
    'title': 'Registrar humor por 5 dias',
    'description': 'Mantenha consistência registrando seu humor por 5 dias seguidos.',
    'xp': 150,
    'category': 'Rotina',
    'isManual': false,
  },
  {
    'id': 'weekly_walk',
    'emoji': '🏃',
    'title': 'Caminhar 5 dias esta semana',
    'description': 'Complete a missão de caminhada diária em pelo menos 5 dias.',
    'xp': 120,
    'category': 'Corpo',
    'isManual': false,
  },
];

class MissionsNotifier extends StateNotifier<MissionsState> {
  final Ref _ref;
  late Box _missionsBox;
  String _userId = 'local_user';
  String _todayKey = '';
  String _weekKey = '';

  MissionsNotifier(this._ref) : super(const MissionsState()) {
    _init();
  }

  Future<void> _init() async {
    _missionsBox = await Hive.openBox('missions_box');
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final supabaseUser = _ref.read(currentUserProvider);
    if (supabaseUser != null) {
      _userId = supabaseUser.id;
    } else {
      _userId = settingsBox.get('current_offline_user_id', defaultValue: 'local_user') as String;
    }

    final now = DateTime.now();
    _todayKey = '${_userId}_daily_${now.year}_${now.month}_${now.day}';
    // Semana ISO: segunda como início
    final weekNum = _isoWeekNumber(now);
    _weekKey = '${_userId}_weekly_${now.year}_$weekNum';

    await _load();
  }

  Future<void> _load() async {
    // Carrega saved states
    final dailySaved = _loadSavedStates(_todayKey);
    final weeklySaved = _loadSavedStates(_weekKey);

    final daily = _dailyTemplates.map((t) {
      final saved = dailySaved[t['id'] as String];
      return MissionData.fromTemplate(t, saved);
    }).toList();

    final weekly = _weeklyTemplates.map((t) {
      final saved = weeklySaved[t['id'] as String];
      return MissionData.fromTemplate(t, saved);
    }).toList();

    state = MissionsState(daily: daily, weekly: weekly, isLoading: false);

    // Auto-checar progresso das missões automáticas
    await _autoUpdateProgress();
  }

  Map<String, Map<String, dynamic>> _loadSavedStates(String boxKey) {
    final raw = _missionsBox.get(boxKey);
    if (raw == null) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw as String));
      return map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveStates(String boxKey, List<MissionData> missions) async {
    final map = {for (final m in missions) m.id: m.toJson()};
    await _missionsBox.put(boxKey, jsonEncode(map));
  }

  /// Atualiza progresso das missões automáticas (conectadas com ações reais)
  Future<void> _autoUpdateProgress() async {
    final moodAsync = _ref.read(moodNotifierProvider);
    final entries = moodAsync.value ?? [];
    final now = DateTime.now();
    final todayEntries = entries.where((e) =>
        e.createdAt.year == now.year &&
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day).toList();

    var daily = List<MissionData>.from(state.daily);
    var weekly = List<MissionData>.from(state.weekly);

    // Missão: Registrar humor hoje
    final moodIdx = daily.indexWhere((m) => m.id == 'daily_mood');
    if (moodIdx != -1 && !daily[moodIdx].isClaimed) {
      final done = todayEntries.isNotEmpty;
      daily[moodIdx] = daily[moodIdx].copyWith(
        progress: done ? 1.0 : 0.0,
        isCompleted: done,
      );
    }

    // Missão: Caminhar (Diária) — se tiver sensor de passos ativo
    final walkIdx = daily.indexWhere((m) => m.id == 'daily_walk');
    if (walkIdx != -1 && !daily[walkIdx].isClaimed) {
      final sensorService = _ref.read(sensorServiceProvider);
      final steps = sensorService.todaySteps;
      if (steps > 0) {
        // 3000 passos = 100% de progresso
        final progress = (steps / 3000).clamp(0.0, 1.0);
        final done = progress >= 1.0;
        daily[walkIdx] = daily[walkIdx].copyWith(
          progress: progress,
          isCompleted: done,
        );
        if (done) {
          await _registerWalkDay();
        }
      }
    }

    // Missão semanal: registrar humor por 5 dias
    final weekMoodIdx = weekly.indexWhere((m) => m.id == 'weekly_sleep');
    if (weekMoodIdx != -1 && !weekly[weekMoodIdx].isClaimed) {
      final daysWithMood = _countDaysWithMoodThisWeek(entries, now);
      final progress = (daysWithMood / 5).clamp(0.0, 1.0);
      weekly[weekMoodIdx] = weekly[weekMoodIdx].copyWith(
        progress: progress,
        isCompleted: daysWithMood >= 5,
      );
    }

    // Missão semanal: caminhar 5 dias (baseado na missão diária de walk concluída)
    final weekWalkIdx = weekly.indexWhere((m) => m.id == 'weekly_walk');
    if (weekWalkIdx != -1 && !weekly[weekWalkIdx].isClaimed) {
      final walkDays = _ref.read(_walkDaysThisWeekProvider(_userId));
      final progress = (walkDays / 5).clamp(0.0, 1.0);
      weekly[weekWalkIdx] = weekly[weekWalkIdx].copyWith(
        progress: progress,
        isCompleted: walkDays >= 5,
      );
    }

    state = state.copyWith(daily: daily, weekly: weekly);
    await _saveStates(_todayKey, daily);
    await _saveStates(_weekKey, weekly);
  }

  int _countDaysWithMoodThisWeek(List entries, DateTime now) {
    final Set<String> days = {};
    for (final e in entries) {
      final d = e.createdAt;
      if (_isoWeekNumber(d) == _isoWeekNumber(now) && d.year == now.year) {
        days.add('${d.month}_${d.day}');
      }
    }
    return days.length;
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
        '${date.difference(DateTime(date.year, 1, 1)).inDays}');
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Chamado quando o usuário envia mensagem para o Mindo
  Future<void> onMindoMessageSent() async {
    var daily = List<MissionData>.from(state.daily);
    final idx = daily.indexWhere((m) => m.id == 'daily_mindo');
    if (idx != -1 && !daily[idx].isClaimed) {
      daily[idx] = daily[idx].copyWith(progress: 1.0, isCompleted: true);
      state = state.copyWith(daily: daily);
      await _saveStates(_todayKey, daily);
    }

    // Missão semanal de respiração: incrementa se a mensagem inclui exercício
    await _incrementBreathingSession();
  }

  Future<void> _incrementBreathingSession() async {
    var weekly = List<MissionData>.from(state.weekly);
    final idx = weekly.indexWhere((m) => m.id == 'weekly_breathing');
    if (idx != -1 && !weekly[idx].isClaimed) {
      final current = (weekly[idx].progress * 5).round();
      if (current < 5) {
        final newCount = current + 1;
        weekly[idx] = weekly[idx].copyWith(
          progress: newCount / 5,
          isCompleted: newCount >= 5,
        );
        state = state.copyWith(weekly: weekly);
        await _saveStates(_weekKey, weekly);
      }
    }
  }

  /// Chamado quando usuário marca missão manual como concluída
  Future<void> toggleManualMission(String missionId, bool isDailyList) async {
    if (isDailyList) {
      var daily = List<MissionData>.from(state.daily);
      final idx = daily.indexWhere((m) => m.id == missionId);
      if (idx != -1 && !daily[idx].isClaimed && daily[idx].isManual) {
        final newProgress = daily[idx].progress >= 1.0 ? 0.0 : 1.0;
        daily[idx] = daily[idx].copyWith(
          progress: newProgress,
          isCompleted: newProgress >= 1.0,
        );
        state = state.copyWith(daily: daily);
        await _saveStates(_todayKey, daily);

        // Se completou missão de caminhada, registra para semanal
        if (missionId == 'daily_walk' && newProgress >= 1.0) {
          await _registerWalkDay();
        }
      }
    }
  }

  Future<void> _registerWalkDay() async {
    final now = DateTime.now();
    final key = '${_userId}_walk_days_${now.year}_${_isoWeekNumber(now)}';
    final raw = _missionsBox.get(key);
    final Set<String> days = raw != null
        ? Set<String>.from(jsonDecode(raw as String) as List)
        : {};
    days.add('${now.month}_${now.day}');
    await _missionsBox.put(key, jsonEncode(days.toList()));
    await _autoUpdateProgress();
  }

  /// Resgata XP de uma missão completada
  Future<void> claimMission(String missionId, bool isDailyList) async {
    if (isDailyList) {
      var daily = List<MissionData>.from(state.daily);
      final idx = daily.indexWhere((m) => m.id == missionId);
      if (idx != -1 && daily[idx].isCompleted && !daily[idx].isClaimed) {
        final xp = daily[idx].xp;
        daily[idx] = daily[idx].copyWith(isClaimed: true);
        state = state.copyWith(daily: daily);
        await _saveStates(_todayKey, daily);
        _ref.read(userProfileNotifierProvider.notifier).addXp(xp);
      }
    } else {
      var weekly = List<MissionData>.from(state.weekly);
      final idx = weekly.indexWhere((m) => m.id == missionId);
      if (idx != -1 && weekly[idx].isCompleted && !weekly[idx].isClaimed) {
        final xp = weekly[idx].xp;
        weekly[idx] = weekly[idx].copyWith(isClaimed: true);
        state = state.copyWith(weekly: weekly);
        await _saveStates(_weekKey, weekly);
        _ref.read(userProfileNotifierProvider.notifier).addXp(xp);
      }
    }
  }

  /// Reseta todas as missões (chamado ao criar novo usuário)
  Future<void> resetAll() async {
    final keysToDelete = _missionsBox.keys
        .where((k) => k.toString().startsWith(_userId))
        .toList();
    for (final k in keysToDelete) {
      await _missionsBox.delete(k);
    }
    await _load();
  }
}

// Provider auxiliar para dias de caminhada na semana
final _walkDaysThisWeekProvider = Provider.family<int, String>((ref, userId) {
  final box = Hive.box('missions_box');
  final now = DateTime.now();
  final weekNum = _isoWeekNumberStatic(now);
  final key = '${userId}_walk_days_${now.year}_$weekNum';
  final raw = box.get(key);
  if (raw == null) return 0;
  try {
    return (jsonDecode(raw as String) as List).length;
  } catch (_) {
    return 0;
  }
});

int _isoWeekNumberStatic(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}
