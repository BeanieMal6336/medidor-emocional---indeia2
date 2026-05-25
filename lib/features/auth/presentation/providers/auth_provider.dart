import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_session.dart';

part 'auth_provider.g.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authNotifierProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    final client = ref.watch(supabaseClientProvider);
    return AsyncValue.data(client.auth.currentUser);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    final trimmedEmail = email.trim();
    try {
      final response = await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(email: trimmedEmail, password: password);
      final user = response.user!;
      final name = (user.userMetadata?['name'] as String?) ??
          _nameFromCredentials(userBox, trimmedEmail) ??
          trimmedEmail.split('@').first;
      await activateUserSession(
        ref,
        userId: user.id,
        email: trimmedEmail,
        name: name,
        offlineMode: false,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      final localData = userBox.get('credentials_$trimmedEmail');
      if (localData != null) {
        final userMap = Map<String, dynamic>.from(jsonDecode(localData as String));
        if (userMap['password'] == password) {
          await activateUserSession(
            ref,
            userId: userMap['id'] as String,
            email: trimmedEmail,
            name: userMap['name'] as String,
            offlineMode: true,
          );
          state = const AsyncValue.data(null);
          return;
        }
        state = AsyncValue.error('Senha incorreta.', st);
        throw Exception('Senha incorreta.');
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    state = const AsyncValue.loading();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final previousId = settingsBox.get('current_offline_user_id') as String?;
    if (previousId != null && previousId != localId) {
      await userBox.delete(previousId);
      await clearUserScopedData(previousId);
    }
    final credentials = {
      'id': localId,
      'email': trimmedEmail,
      'name': trimmedName,
      'password': password,
    };
    await userBox.put('credentials_$trimmedEmail', jsonEncode(credentials));
    final registryList = settingsBox.get('offline_email_registry', defaultValue: <dynamic>[]) as List;
    final updatedList = List<String>.from(registryList.map((e) => e.toString()));
    if (!updatedList.contains(trimmedEmail)) {
      updatedList.add(trimmedEmail);
      await settingsBox.put('offline_email_registry', updatedList);
    }
    try {
      final response = await ref.read(supabaseClientProvider).auth.signUp(
            email: trimmedEmail,
            password: password,
            data: {'name': trimmedName},
          );
      final supabaseId = response.user?.id ?? localId;
      await activateUserSession(
        ref,
        userId: supabaseId,
        email: trimmedEmail,
        name: trimmedName,
        offlineMode: response.user == null,
        isNewUser: true,
      );
      if (supabaseId != localId) {
        await userBox.put(supabaseId, jsonEncode({
          'id': supabaseId,
          'email': trimmedEmail,
          'name': trimmedName,
          'total_xp': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'created_at': DateTime.now().toIso8601String(),
          'is_onboarding_done': true,
        }));
      }
      state = AsyncValue.data(response.user);
    } catch (_) {
      await activateUserSession(
        ref,
        userId: localId,
        email: trimmedEmail,
        name: trimmedName,
        offlineMode: true,
        isNewUser: true,
      );
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signInWithGoogleSimulated(String email, String name) async {
    state = const AsyncValue.loading();
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final localId = 'google_${DateTime.now().millisecondsSinceEpoch}';
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    await userBox.put(
      'credentials_$trimmedEmail',
      jsonEncode({
        'id': localId,
        'email': trimmedEmail,
        'name': trimmedName,
        'password': 'google_simulated_password_123',
      }),
    );
    final registryList = settingsBox.get('offline_email_registry', defaultValue: <dynamic>[]) as List;
    final updatedList = List<String>.from(registryList.map((e) => e.toString()));
    if (!updatedList.contains(trimmedEmail)) {
      updatedList.add(trimmedEmail);
      await settingsBox.put('offline_email_registry', updatedList);
    }
    await activateUserSession(
      ref,
      userId: localId,
      email: trimmedEmail,
      name: trimmedName,
      offlineMode: true,
      isNewUser: true,
    );
    state = const AsyncValue.data(null);
  }

  Future<void> signInWithGoogle() async {
    throw UnimplementedError('Utilize o fluxo Gmail Simulado.');
  }

  Future<void> signOut() async {
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    await settingsBox.put('offline_mode', false);
    await settingsBox.delete('current_offline_user_id');
    await settingsBox.delete('current_offline_user_email');
    await settingsBox.delete('current_offline_user_name');
    await ref.read(supabaseClientProvider).auth.signOut();
    invalidateUserScopedProviders(ref);
    state = const AsyncValue.data(null);
  }

  String? _nameFromCredentials(Box userBox, String email) {
    final raw = userBox.get('credentials_$email');
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw as String));
      return map['name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
