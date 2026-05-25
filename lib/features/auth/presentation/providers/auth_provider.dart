import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

part 'auth_provider.g.dart';

// ── Supabase client ───────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ── Auth state stream ─────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// ── Current user ──────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// ── Auth notifier ─────────────────────────────────────────
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

    try {
      // Tenta logar pelo Supabase se estiver online
      final response = await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(email: email, password: password);
      
      await settingsBox.put('offline_mode', false);
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      // Se falhar ou estiver offline, tenta login local
      final localData = userBox.get('credentials_$email');
      if (localData != null) {
        final Map<String, dynamic> userMap = Map<String, dynamic>.from(jsonDecode(localData as String));
        if (userMap['password'] == password) {
          await settingsBox.put('offline_mode', true);
          await settingsBox.put('current_offline_user_id', userMap['id']);
          await settingsBox.put('current_offline_user_email', email);
          await settingsBox.put('current_offline_user_name', userMap['name']);
          
          state = const AsyncValue.data(null); // Sem usuário Supabase (modo offline ativo)
          return;
        } else {
          state = AsyncValue.error('Senha incorreta localmente.', st);
          throw Exception('Senha incorreta localmente.');
        }
      }
      
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    state = const AsyncValue.loading();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final userBox = Hive.box(AppConstants.hiveBoxUser);
    
    // Gerar ID local para o caso de offline
    final String localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // Sempre salvar credenciais localmente primeiro (banco de dados local de cadastro)
    final credentials = {
      'id': localId,
      'email': email,
      'name': name,
      'password': password,
    };
    await userBox.put('credentials_$email', jsonEncode(credentials));

    // Registrar e-mail no banco de dados local
    final registryList = settingsBox.get('offline_email_registry', defaultValue: <dynamic>[]) as List;
    final updatedList = List<String>.from(registryList.map((e) => e.toString()));
    if (!updatedList.contains(email)) {
      updatedList.add(email);
      await settingsBox.put('offline_email_registry', updatedList);
    }

    try {
      // Tenta cadastrar no Supabase
      final response = await ref
          .read(supabaseClientProvider)
          .auth
          .signUp(
            email: email,
            password: password,
            data: {'name': name},
          );
      
      await settingsBox.put('offline_mode', false);
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      // Se falhar (ex: sem internet), entra no modo offline com o cadastro recém criado
      await settingsBox.put('offline_mode', true);
      await settingsBox.put('current_offline_user_id', localId);
      await settingsBox.put('current_offline_user_email', email);
      await settingsBox.put('current_offline_user_name', name);
      
      state = const AsyncValue.data(null); // Sem usuário Supabase (modo offline ativo)
    }
  }

  Future<void> signInWithGoogleSimulated(String email, String name) async {
    state = const AsyncValue.loading();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final userBox = Hive.box(AppConstants.hiveBoxUser);

    final String localId = 'google_${DateTime.now().millisecondsSinceEpoch}';

    // Salva no banco de dados local
    final credentials = {
      'id': localId,
      'email': email,
      'name': name,
      'password': 'google_simulated_password_123',
    };
    await userBox.put('credentials_$email', jsonEncode(credentials));

    // Registrar e-mail no banco de dados local
    final registryList = settingsBox.get('offline_email_registry', defaultValue: <dynamic>[]) as List;
    final updatedList = List<String>.from(registryList.map((e) => e.toString()));
    if (!updatedList.contains(email)) {
      updatedList.add(email);
      await settingsBox.put('offline_email_registry', updatedList);
    }

    await settingsBox.put('offline_mode', true);
    await settingsBox.put('current_offline_user_id', localId);
    await settingsBox.put('current_offline_user_email', email);
    await settingsBox.put('current_offline_user_name', name);
    
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
    state = const AsyncValue.data(null);
  }
}
