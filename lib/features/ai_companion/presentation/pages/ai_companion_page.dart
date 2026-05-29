import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../../core/services/mindo_engine.dart';
import '../../../../core/domain/entities/ai_message.dart';
import '../../../../core/domain/entities/mindo_conversation.dart';
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
  bool _isCreatingConversation = false; // Evita criações concorrentes
  MindoConversationState _conversationState = const MindoConversationState();
  List<AiMessage> _cachedMessages = []; // Mantém mensagens visíveis durante transições

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

     final conversationsAsync = ref.read(mindoConversationsProvider);
     conversationsAsync.whenOrNull(
       data: (conversations) async {
         if (conversations.isNotEmpty) {
           final latest = conversations.first;
           ref.read(activeConversationIdProvider.notifier).state = latest.id;
           if (mounted) {
             setState(() => _conversationId = latest.id);
             _loadConversationState();
           }
         } else {
           await _createNewConversation(silent: true);
         }
       },
       error: (_) async {
         // Se erro, tenta criar nova conversa
         await _createNewConversation(silent: true);
       },
     );
     // Se ainda está carregando, o listen vai tratar quando carregar
   }

// ── Cria nova conversa e envia mensagem de boas-vindas ──────────────────
   Future<void> _createNewConversation({bool silent = false}) async {
     // Evita criações concorrentes (ex: duplo clique ou race condition)
     if (_isCreatingConversation) return;
     setState(() => _isCreatingConversation = true);

     try {
       final conv = await ref
           .read(mindoConversationsProvider.notifier)
           .createConversation();

       if (!mounted) return;

       ref.read(activeConversationIdProvider.notifier).state = conv.id;
       setState(() => _conversationId = conv.id);

       // Mensagem de boas-vindas - aguarda o provider estar pronto
       final profileAsync = ref.read(userProfileNotifierProvider);
       String name = '';
       
       if (profileAsync.hasValue) {
         final profile = profileAsync.value;
         name = profile?.displayName ?? profile?.name ?? '';
       }
       
       // Aguarda um frame para garantir que o provider de mensagens foi criado
       await Future.delayed(const Duration(milliseconds: 100));
       
       if (!mounted) return;
       
       try {
         // Aguarda o provider estar inicializado
         final messagesNotifier = ref.read(mindoMessagesProvider(conv.id).notifier);
         await messagesNotifier.addMessage(
               content: MindoEngine.welcomeMessage(name),
               role: MessageRole.assistant,
             );
         
         // Carrega estado após mensagem ser salva
         if (mounted) {
           _loadConversationState();
           _scrollToBottom();
         }
       } catch (e) {
         // Corrige o erro silencioso - mostra snackbar se falhar
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao iniciar conversa: $e')),
           );
           // Mesmo com erro, carrega o estado
           _loadConversationState();
           _scrollToBottom();
         }
       }
     } catch (e) {
       // Erro na criação da conversa
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao criar conversa: $e')),
         );
       }
     } finally {
       if (mounted) setState(() => _isCreatingConversation = false);
     }
   }

   // ── Carrega o estado da conversa (contexto do motor Mindo) ───────────────
  void _loadConversationState() {
    final messages =
        ref.read(mindoMessagesProvider(_conversationId!)).value ?? [];

    // Conta mensagens do usuário
    final userCount = messages.where((m) => m.isUser).length;

    // Reconstrói histórico recente das mensagens do usuário (últimas 6)
    final userMessages = messages
        .where((m) => m.isUser)
        .map((m) => m.content.toLowerCase().trim())
        .toList();
    final recentHistory = userMessages.length > 6
        ? userMessages.sublist(userMessages.length - 6)
        : userMessages;

    // Detecta rapport com base no total de trocas
    final rapportLevel = (userCount * 2).clamp(0, 10);

    // Mantém o estado atual se já foi carregado para esta conversa
    // (evita reset ao reconstruir o widget)
    if (_conversationState.userMessageCount == userCount &&
        _conversationId != null) {
      return;
    }

    _conversationState = MindoConversationState(
      userMessageCount: userCount,
      rapportLevel: rapportLevel,
      recentUserMessages: recentHistory,
      // awaitingFreeResponse: true indica que o Mindo fez uma pergunta
      // na última mensagem dele — ativamos se a última msg for do assistant
      awaitingFreeResponse:
          messages.isNotEmpty && !messages.last.isUser,
    );
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
    // Bloqueia envio duplo ou enquanto o Mindo está respondendo
    if (text.isEmpty || _conversationId == null || _isTyping) return;

    _textController.clear();
    setState(() => _isTyping = true);

    try {
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

      // Delay proporcional ao tamanho da resposta (simula digitação)
      final delayMs = 600 + (reply.text.length * 2).clamp(0, 2000);
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
    } catch (_) {
      // Garante que o estado de digitação sempre volta ao normal
      if (mounted) setState(() => _isTyping = false);
    }
  }


  // ── Confirma reset e cria nova conversa ─────────────────────────────────
  Future<void> _resetConversation() async {
    // await garante que o dialog seja tratado de forma síncrona,
    // evitando race conditions com o ref.listen
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nova Conversa',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Só cria nova conversa se o usuário confirmou
    if (confirmed == true && mounted) {
      await _createNewConversation();
    }
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
              } else if (!_isCreatingConversation) {
                // Só cria se não estiver já criando
                _createNewConversation(silent: true);
              }
            }
          },
          error: (_) {
            // Se erro, garante que não fica travado
            if (!_isCreatingConversation) {
              _createNewConversation(silent: true);
            }
          },
        );
      },
    );

    // Escuta a conversa ativa para sincronizar o estado da UI local
    ref.listen<String?>(activeConversationIdProvider, (previous, next) {
      // Ignora transições para null durante criação de nova conversa
      // para evitar limpar a UI momentaneamente
      if (next == null && _isCreatingConversation) return;

      if (next != previous) {
        setState(() {
          // Só atualiza _conversationId se o próximo não é null,
          // ou se é null e não estamos criando (ex: logout)
          if (next != null) _conversationId = next;
          // Reseta apenas o estado de digitação — o resto é reconstruído
          // pelo _loadConversationState após as mensagens carregarem
          _conversationState = const MindoConversationState();
          _isTyping = false;
        });
        if (next != null) {
          // Aguarda um frame para as mensagens do provider serem lidas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadConversationState();
              _scrollToBottom();
            }
          });
        }
      }
    });

    final conversationsAsync = ref.watch(mindoConversationsProvider);

    // Observa mensagens da conversa ativa
    final messagesAsync = _conversationId != null
        ? ref.watch(mindoMessagesProvider(_conversationId!))
        : const AsyncValue<List<AiMessage>>.data([]);

    // Atualiza cache sempre que há dados reais — evita tela preta na transição
    if (messagesAsync is AsyncData<List<AiMessage>>) {
      _cachedMessages = messagesAsync.value!;
    }

    final messages = messagesAsync.value ?? _cachedMessages;
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
                : Stack(
                    children: [
                      // Exibe mensagens (cache ou atuais) — nunca deixa tela preta
                      messagesAsync.when(
                        loading: () => _buildMessageList(_cachedMessages, typing: false),
                        error: (e, _) => Center(
                          child: Text('Erro ao carregar mensagens',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        data: (msgs) => _buildMessageList(msgs, typing: _isTyping),
                      ),
                      // Barra de progresso sutil no topo durante criação/carregamento
                      if (_isCreatingConversation || messagesAsync is AsyncLoading)
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
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

  // ── Lista de mensagens (usada para dados reais e para cache durante loading) ──
  Widget _buildMessageList(List<AiMessage> msgs, {required bool typing}) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: msgs.length + (typing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == msgs.length) return _TypingIndicator();
        final msg = msgs[index];
        return _MessageBubble(
          role: msg.role,
          content: msg.content,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
      },
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




