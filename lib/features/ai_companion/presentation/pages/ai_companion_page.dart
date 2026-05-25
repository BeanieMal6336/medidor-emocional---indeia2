import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../../core/services/mindo_engine.dart';
import '../../../../core/domain/entities/ai_message.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../gamification/providers/missions_provider.dart';
import '../../providers/mindo_chat_provider.dart';
import 'mindo_history_page.dart';

class AiCompanionPage extends ConsumerStatefulWidget {
  const AiCompanionPage({super.key});

  @override
  ConsumerState<AiCompanionPage> createState() => _AiCompanionPageState();
}

class _AiCompanionPageState extends ConsumerState<AiCompanionPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _engine = MindoEngine();
  bool _isTyping = false;
  MindoConversationState _conversationState = const MindoConversationState();

  // ID da conversa ativa (gerenciado pelo provider)
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureActiveConversation();
    });
  }

  // ── Garante que existe uma conversa ativa ao abrir a página ─────────────
  Future<void> _ensureActiveConversation() async {
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId != null) {
      setState(() => _conversationId = activeId);
      _loadConversationState();
      _scrollToBottom();
      return;
    }

    final conversationsState = ref.read(mindoConversationsProvider);
    if (conversationsState is AsyncData<List<MindoConversation>>) {
      final conversations = conversationsState.value;
      if (conversations.isNotEmpty) {
        final latest = conversations.first;
        ref.read(activeConversationIdProvider.notifier).state = latest.id;
      } else {
        await _createNewConversation(silent: true);
      }
    }
  }

  // ── Cria nova conversa e envia mensagem de boas-vindas ──────────────────
  Future<void> _createNewConversation({bool silent = false}) async {
    final conv = await ref
        .read(mindoConversationsProvider.notifier)
        .createConversation();

    ref.read(activeConversationIdProvider.notifier).state = conv.id;

    // Mensagem de boas-vindas
    final profile = ref.read(userProfileNotifierProvider).value;
    final name = profile?.displayName ?? '';
    await ref.read(mindoMessagesProvider(conv.id).notifier).addMessage(
          content: MindoEngine.welcomeMessage(name),
          role: MessageRole.assistant,
        );
  }

  // ── Carrega o estado da conversa (contexto do motor Mindo) ───────────────
  void _loadConversationState() {
    // O estado do motor é reconstruído a partir do histórico de mensagens.
    // Como o MindoEngine é stateless no envio, mantemos apenas o counter.
    final messages = ref.read(mindoMessagesProvider(_conversationId!)).value ?? [];
    final userCount = messages.where((m) => m.isUser).length;
    _conversationState = MindoConversationState(userMessageCount: userCount);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Envia mensagem ───────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _textController.clear();
    setState(() => _isTyping = true);

    // Salva mensagem do usuário
    await ref
        .read(mindoMessagesProvider(_conversationId!).notifier)
        .addMessage(content: text, role: MessageRole.user);

    _scrollToBottom();

    // Missão diária
    ref.read(missionsProvider.notifier).onMindoMessageSent();

    // Gera resposta do Mindo
    final profile = ref.read(userProfileNotifierProvider).value;
    final moods = ref.read(moodNotifierProvider).value ?? [];
    final now = DateTime.now();
    final loggedToday = moods.any((e) =>
        e.createdAt.year == now.year &&
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day);
    final days = profile == null
        ? 1
        : DateTime.now().difference(profile.createdAt).inDays + 1;

    final userCtx = MindoUserContext(
      displayName: profile?.displayName ?? '',
      totalXp: profile?.totalXp ?? 0,
      currentStreak: profile?.currentStreak ?? 0,
      level: profile?.level ?? LevelType.seedling,
      daysOnJourney: days,
      moodEntriesCount: moods.length,
      loggedMoodToday: loggedToday,
      meditationSessions: 0,
    );

    final reply = _engine.respond(
      input: text,
      state: _conversationState,
      user: userCtx,
    );

    final delayMs = 600 + (reply.text.length * 2).clamp(0, 2200);
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!mounted) return;

    await ref.read(userProfileNotifierProvider.notifier).addXp(8);

    setState(() {
      _isTyping = false;
      _conversationState = reply.state;
    });

    await ref
        .read(mindoMessagesProvider(_conversationId!).notifier)
        .addMessage(content: reply.text, role: MessageRole.assistant);

    _scrollToBottom();
  }

  // ── Confirma reset e cria nova conversa ─────────────────────────────────
  Future<void> _resetConversation() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Nova Conversa?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'A conversa atual será salva no histórico e você começará uma nova do zero.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createNewConversation();
            },
            child: const Text('Nova Conversa',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Abre o histórico de conversas ────────────────────────────────────────
  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MindoHistoryPage(
          onSelect: (conv) {
            ref.read(activeConversationIdProvider.notifier).state = conv.id;
            Navigator.of(context).pop();
          },
          onNewConversation: () {
            Navigator.of(context).pop();
            _createNewConversation();
          },
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta mudanças nas sessões de conversas para definir a conversa ativa inicial
    ref.listen<AsyncValue<List<MindoConversation>>>(
      mindoConversationsProvider,
      (previous, next) {
        next.whenOrNull(
          data: (conversations) {
            final activeId = ref.read(activeConversationIdProvider);
            if (activeId == null) {
              if (conversations.isNotEmpty) {
                final latest = conversations.first;
                ref.read(activeConversationIdProvider.notifier).state = latest.id;
              } else {
                _createNewConversation(silent: true);
              }
            }
          },
        );
      },
    );

    // Escuta a conversa ativa para sincronizar o estado da UI local
    ref.listen<String?>(activeConversationIdProvider, (previous, next) {
      if (next != previous) {
        setState(() {
          _conversationId = next;
          _conversationState = const MindoConversationState();
        });
        if (next != null) {
          _loadConversationState();
          _scrollToBottom();
        }
      }
    });

    final conversationsAsync = ref.watch(mindoConversationsProvider);

    // Observa mensagens da conversa ativa
    final messagesAsync = _conversationId != null
        ? ref.watch(mindoMessagesProvider(_conversationId!))
        : const AsyncValue<List<AiMessage>>.data([]);
    final messages = messagesAsync.value ?? [];
    final isReady = _conversationId != null && messagesAsync is! AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (context.mounted) Navigator.of(context).maybePop();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child:
                  const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mindo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online — Companheiro Emocional',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.accentGreen)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botão histórico
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textMuted),
            tooltip: 'Histórico',
            onPressed: _openHistory,
          ),
          // Botão nova conversa
          IconButton(
            icon: const Icon(Icons.add_comment_outlined,
                color: AppColors.textMuted),
            tooltip: 'Nova Conversa',
            onPressed: _resetConversation,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppColors.textMuted),
            onPressed: _showAiInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.accent.withOpacity(0.08),
            child: const Row(
              children: [
                Text('💜', style: TextStyle(fontSize: 13)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mindo é um suporte emocional — não substitui terapia profissional. Em crise: CVV 188.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _conversationId == null && conversationsAsync.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : messagesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) => Center(
                      child: Text('Erro ao carregar mensagens',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    data: (msgs) => ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: msgs.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == msgs.length) {
                          return _TypingIndicator();
                        }
                        final msg = msgs[index];
                        return _MessageBubble(
                          role: msg.role,
                          content: msg.content,
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
                      },
                    ),
                  ),
          ),
          // Sugestões rápidas (somente início da conversa)
          if (isReady && _conversationState.userMessageCount == 0 && messages.length <= 1)
            _buildQuickSuggestions(),
          // Input
          _ChatInput(
            controller: _textController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Estou ansioso(a)',
      'Meditação guiada',
      'Pensamento negativo',
      'Preciso desabafar',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: suggestions
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      _textController.text = s;
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _showAiInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sobre o Mindo 🤖',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'O Mindo é um motor emocional local (sem API) com:\n\n• 🧠 Memória da conversa e rapport progressivo\n• 🧘 Meditação guiada passo a passo\n• 📓 Técnicas CBT (reestruturação de pensamentos)\n• 🌿 Grounding, respiração e regulação\n• 📊 Contexto do seu perfil e jornada no app\n\n⚠️ Não substitui psicólogo/terapeuta. Crise: CVV **188**.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Entendi',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bubble de mensagem ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageRole role;
  final String content;

  const _MessageBubble({required this.role, required this.content});

  bool get isUser => role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child:
                  const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.gradientPrimary : null,
                color: isUser ? null : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border:
                    isUser ? null : Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Indicador de digitação ────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child:
                const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                        delay: Duration(milliseconds: i * 200),
                        onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.6, 0.6))
                    .fadeIn(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input de texto ────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgMedium,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Como você está se sentindo?',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
                boxShadow: AppColors.shadowPrimary,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
