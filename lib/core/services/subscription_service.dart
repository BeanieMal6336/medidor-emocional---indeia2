import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../constants/app_constants.dart';
import '../../domain/enums/subscription_type.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// ─── Provider: subscription tier do usuário atual ────────────────────────────

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionType>((ref) {
  return SubscriptionNotifier(ref);
});

class SubscriptionNotifier extends StateNotifier<SubscriptionType> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(SubscriptionType.free) {
    _load();
  }

  void _load() {
    try {
      final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
      final profileProvider = _ref.read(userProfileNotifierProvider);
      // Prioridade 1: perfil Supabase
      final serverSub = profileProvider.value?.subscription;
      if (serverSub != null && serverSub != SubscriptionType.free) {
        state = serverSub;
        return;
      }
      // Prioridade 2: cache local
      final cached = settingsBox.get('subscription_type') as String?;
      state = SubscriptionType.fromJson(cached);
    } catch (_) {
      state = SubscriptionType.free;
    }
  }

  /// Simula ativação de plano (em produção: validar receipt server-side).
  Future<void> activate(SubscriptionType type) async {
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    await settingsBox.put('subscription_type', type.toJson());
    await settingsBox.put('subscription_expires_at', expiresAt.toIso8601String());

    // Persiste no perfil local também
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    final currentUserId = settingsBox.get('current_offline_user_id') as String? ??
        _ref.read(userProfileNotifierProvider).value?.id;
    if (currentUserId != null) {
      final raw = userBox.get(currentUserId);
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(raw as String));
          map['subscription'] = type.toJson();
          map['subscription_expires_at'] = expiresAt.toIso8601String();
          await userBox.put(currentUserId, jsonEncode(map));
        } catch (_) {}
      }
    }
    state = type;
  }

  Future<void> cancel() async {
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    await settingsBox.put('subscription_type', SubscriptionType.free.toJson());
    await settingsBox.delete('subscription_expires_at');
    state = SubscriptionType.free;
  }

  DateTime? get expiresAt {
    try {
      final raw = Hive.box(AppConstants.hiveBoxSettings).get('subscription_expires_at') as String?;
      return raw != null ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }
}
