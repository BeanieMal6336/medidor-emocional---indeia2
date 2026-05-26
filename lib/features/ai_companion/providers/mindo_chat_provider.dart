import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/entities/mindo_conversation.dart';
import '../../../core/domain/entities/ai_message.dart';
import '../../../core/utils/user_session.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../mood_tracker/providers/mood_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider de sessões de conversa
// ─────────────────────────────────────────────────────────────────────────────

/// Gerencia a lista de sessões de conversa do usuário ativo.
/// Completamente isolado por userId — trocar de usuário invalida este provider.
final mindoConversationsProvider =
    StateNotifierProvider<MindoConversationsNotifier, AsyncValue<List<MindoConversation>>>(
  (ref) => MindoConversationsNotifier(ref),
);

class MindoConversationsNotifier
    extends StateNotifier<AsyncValue<List<MindoConversation>>> {
  final Ref _ref;
  final Completer<void> _initCompleter = Completer<void>();
  late Box _conversationsBox;
  String _userId = '';

  MindoConversationsNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _conversationsBox =
          await Hive.openBox(AppConstants.hiveBoxMindoConversations);
      _userId = _ref.read(activeUserIdProvider);
      await _load();
      _initCompleter.complete();

      // Sincroniza com Supabase se online
      final hasUser = _ref.read(currentUserProvider) != null;
      if (hasUser) _syncFromSupabase();
    } catch (e, st) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, st);
      }
    }
  }

  // ── Carrega do Hive (somente do usuário ativo) ──────────────────────────
  Future<void> _load() async {
    final List<MindoConversation> conversations = [];
    for (final key in _conversationsBox.keys) {
      if (!key.toString().startsWith('conv_${_userId}_')) continue;
      final raw = _conversationsBox.get(key) as String?;
      if (raw == null) continue;
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        final conv = MindoConversation.fromJson(map);
        if (conv.userId == _userId) conversations.add(conv);
      } catch (_) {}
    }
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncValue.data(conversations);
  }

  // ── Sincroniza do Supabase ──────────────────────────────────────────────
  Future<void> _syncFromSupabase() async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('mindo_conversations')
          .select()
          .eq('user_id', _userId)
          .order('updated_at', ascending: false);

      final List<MindoConversation> remote = (response as List)
          .map((e) =>
              MindoConversation.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      for (final conv in remote) {
        final hiveKey = 'conv_${_userId}_${conv.id}';
        await _conversationsBox.put(hiveKey, jsonEncode(conv.toJson()));
      }

      remote.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncValue.data(remote);
    } catch (_) {
      // Offline-first: continua com dados locais em caso de erro
    }
  }

  // ── Cria nova sessão de conversa ────────────────────────────────────────
  Future<MindoConversation> createConversation({String? title}) async {
    await _initCompleter.future;
    final id = const Uuid().v4();
    final now = DateTime.now();
    final conv = MindoConversation(
      id: id,
      userId: _userId,
      title: title ?? 'Nova Conversa',
      createdAt: now,
      updatedAt: now,
    );

    final hiveKey = 'conv_${_userId}_$id';
    await _conversationsBox.put(hiveKey, jsonEncode(conv.toJson()));

    final current = state.value ?? [];
    state = AsyncValue.data([conv, ...current]);

    // Salva no Supabase se online (background, sem await)
    final hasUser = _ref.read(currentUserProvider) != null;
    if (hasUser) {
      final supabase = _ref.read(supabaseClientProvider);
      supabase.from('mindo_conversations').insert(conv.toJson()).catchError((_) {
        // ignore offline save error
      });
    }

    return conv;
  }

  // ── Atualiza metadados de uma sessão (título, lastMessage, count) ───────
  Future<void> updateConversation(MindoConversation updated) async {
    await _initCompleter.future;
    final hiveKey = 'conv_${_userId}_${updated.id}';
    await _conversationsBox.put(hiveKey, jsonEncode(updated.toJson()));

    final current = state.value ?? [];
    final idx = current.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;

    final newList = List<MindoConversation>.from(current);
    newList[idx] = updated;
    newList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncValue.data(newList);

    // Sincroniza no Supabase (background, sem await)
    final hasUser = _ref.read(currentUserProvider) != null;
    if (hasUser) {
      final supabase = _ref.read(supabaseClientProvider);
      supabase
          .from('mindo_conversations')
          .upsert(updated.toJson())
          .catchError((_) {
        // ignore offline save error
      });
    }
  }

  // ── Deleta uma sessão e todas as suas mensagens ─────────────────────────
  Future<void> deleteConversation(String conversationId) async {
    await _initCompleter.future;
    // Remove conversa do Hive
    await _conversationsBox.delete('conv_${_userId}_$conversationId');

    // Remove mensagens locais
    final messagesBox = await Hive.openBox(AppConstants.hiveBoxMindoMessages);
    final msgKeys = messagesBox.keys
        .where((k) => k.toString().startsWith('msg_${_userId}_${conversationId}_'))
        .toList();
    for (final k in msgKeys) {
      await messagesBox.delete(k);
    }

    // Atualiza state
    final current = state.value ?? [];
    state = AsyncValue.data(
        current.where((c) => c.id != conversationId).toList());

    // Remove no Supabase (background, sem await)
    final hasUser = _ref.read(currentUserProvider) != null;
    if (hasUser) {
      final supabase = _ref.read(supabaseClientProvider);
      supabase
          .from('mindo_conversations')
          .delete()
          .eq('id', conversationId)
          .catchError((_) {});
      supabase
          .from('ai_conversations')
          .delete()
          .eq('conversation_id', conversationId)
          .catchError((_) {});
    }
  }

  // ── Limpa TODOS os dados do usuário (troca de conta) ───────────────────
  Future<void> clearAllForUser(String userId) async {
    await _initCompleter.future;
    final keysToDelete = _conversationsBox.keys
        .where((k) => k.toString().startsWith('conv_${userId}_'))
        .toList();
    for (final k in keysToDelete) {
      await _conversationsBox.delete(k);
    }
    if (_userId == userId) {
      state = const AsyncValue.data([]);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider de mensagens de uma conversa específica
// ─────────────────────────────────────────────────────────────────────────────

/// Gerencia as mensagens de uma sessão específica.
/// Family por conversationId — cada sessão tem seu próprio estado isolado.
final mindoMessagesProvider = StateNotifierProvider.family<
    MindoMessagesNotifier, AsyncValue<List<AiMessage>>, String>(
  (ref, conversationId) => MindoMessagesNotifier(ref, conversationId),
);

class MindoMessagesNotifier
    extends StateNotifier<AsyncValue<List<AiMessage>>> {
  final Ref _ref;
  final String conversationId;
  final Completer<void> _initCompleter = Completer<void>();
  late Box _messagesBox;
  String _userId = '';

  MindoMessagesNotifier(this._ref, this.conversationId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _messagesBox = await Hive.openBox(AppConstants.hiveBoxMindoMessages);
      _userId = _ref.read(activeUserIdProvider);
      await _load();
      _initCompleter.complete();

      // Sincroniza mensagens do Supabase se online
      final hasUser = _ref.read(currentUserProvider) != null;
      if (hasUser) _syncFromSupabase();
    } catch (e, st) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, st);
      }
    }
  }

  // ── Carrega mensagens do Hive para esta conversa + usuário ──────────────
  Future<void> _load() async {
    final List<AiMessage> messages = [];
    final prefix = 'msg_${_userId}_${conversationId}_';
    for (final key in _messagesBox.keys) {
      if (!key.toString().startsWith(prefix)) continue;
      final raw = _messagesBox.get(key) as String?;
      if (raw == null) continue;
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        messages.add(AiMessage.fromJson(map));
      } catch (_) {}
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = AsyncValue.data(messages);
  }

  // ── Sincroniza mensagens do Supabase ────────────────────────────────────
  Future<void> _syncFromSupabase() async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('ai_conversations')
          .select()
          .eq('user_id', _userId)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final List<AiMessage> remote = (response as List)
          .map((e) => AiMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      for (final msg in remote) {
        final key = 'msg_${_userId}_${conversationId}_${msg.id}';
        await _messagesBox.put(key, jsonEncode(msg.toJson()));
      }

      state = AsyncValue.data(remote);
    } catch (_) {}
  }

  // ── Adiciona uma nova mensagem ──────────────────────────────────────────
  Future<AiMessage> addMessage({
    required String content,
    required MessageRole role,
  }) async {
    await _initCompleter.future;
    final id = const Uuid().v4();
    final now = DateTime.now();
    final msg = AiMessage(
      id: id,
      content: content,
      role: role,
      createdAt: now,
      conversationId: conversationId,
    );

    // Salva localmente
    final key = 'msg_${_userId}_${conversationId}_$id';
    await _messagesBox.put(key, jsonEncode(msg.toJson()));

    // Atualiza state
    final current = state.value ?? [];
    state = AsyncValue.data([...current, msg]);

    // Atualiza metadados da conversa (lastMessage, count, updatedAt)
    _updateConversationMeta(content, current.length + 1);

    // Salva no Supabase (background, sem await)
    final hasUser = _ref.read(currentUserProvider) != null;
    if (hasUser) {
      final supabase = _ref.read(supabaseClientProvider);
      supabase.from('ai_conversations').insert({
        'id': id,
        'user_id': _userId,
        'content': content,
        'role': role.name,
        'created_at': now.toIso8601String(),
        'conversation_id': conversationId,
      }).catchError((_) {
        // ignore offline save error
      });
    }

    return msg;
  }

  // ── Atualiza metadados da sessão pai ────────────────────────────────────
  void _updateConversationMeta(String lastContent, int count) {
    final conversations = _ref.read(mindoConversationsProvider).value ?? [];
    final conv = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => MindoConversation(
        id: conversationId,
        userId: _userId,
        title: 'Conversa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Gera título a partir da primeira mensagem do usuário
    String title = conv.title;
    if (title == 'Nova Conversa' && count == 1) {
      title = lastContent.length > 40
          ? '${lastContent.substring(0, 40)}…'
          : lastContent;
    }

    final updated = conv.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      messageCount: count,
      lastMessage: lastContent.length > 80
          ? '${lastContent.substring(0, 80)}…'
          : lastContent,
    );

    _ref.read(mindoConversationsProvider.notifier).updateConversation(updated);
  }

  // ── Limpa todas as mensagens desta conversa (reset local) ───────────────
  Future<void> clearMessages() async {
    await _initCompleter.future;
    final prefix = 'msg_${_userId}_${conversationId}_';
    final keys = _messagesBox.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    for (final k in keys) {
      await _messagesBox.delete(k);
    }
    state = const AsyncValue.data([]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider da conversa ativa atual (ID)
// ─────────────────────────────────────────────────────────────────────────────

/// Mantém o ID da conversa ativa. Null = nenhuma selecionada.
final activeConversationIdProvider = StateProvider<String?>((ref) => null);

/// Retorna a conversa ativa como objeto completo.
final activeConversationProvider = Provider<MindoConversation?>((ref) {
  final id = ref.watch(activeConversationIdProvider);
  if (id == null) return null;
  final conversations = ref.watch(mindoConversationsProvider).value ?? [];
  try {
    return conversations.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
