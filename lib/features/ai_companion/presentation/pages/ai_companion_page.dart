import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/domain/enums/level_type.dart';
import '../../../../core/services/mindo_engine.dart';
import '../../../../core/utils/user_session.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../gamification/providers/missions_provider.dart';

class AiCompanionPage extends ConsumerStatefulWidget {
  const AiCompanionPage({super.key});

  @override
  ConsumerState<AiCompanionPage> createState() => _AiCompanionPageState();
}

class _AiCompanionPageState extends ConsumerState<AiCompanionPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _engine = MindoEngine();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  MindoConversationState _conversationState = const MindoConversationState();
  late Box _chatBox;
  late String _userId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _userId = resolveCurrentUserId();
    _chatBox = await Hive.openBox('mindo_chat_box');
    final stateRaw = _chatBox.get('state_$_userId');
    if (stateRaw != null) {
      try {
        _conversationState = MindoConversationState.fromJson(
          Map<String, dynamic>.from(jsonDecode(stateRaw as String)),
        );
      } catch (_) {}
    }
    final profile = ref.read(userProfileNotifierProvider).value;
    final name = profile?.displayName ?? '';
    final List<dynamic>? raw = _chatBox.get('messages_$_userId') as List<dynamic>?;
    setState(() {
      _messages.clear();
      if (raw != null && raw.isNotEmpty) {
        for (final m in raw) {
          final map = Map<String, dynamic>.from(m as Map);
          _messages.add(_ChatMessage(
            role: map['role'] as String,
            content: map['content'] as String,
            time: DateTime.parse(map['time'] as String),
          ));
        }
      } else {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: MindoEngine.welcomeMessage(name),
          time: DateTime.now(),
        ));
      }
      _ready = true;
    });
    _scrollToBottom();
  }

  Future<void> _saveSession() async {
    final list = _messages.map((m) => {
      'role': m.role,
      'content': m.content,
      'time': m.time.toIso8601String(),
    }).toList();
    await _chatBox.put('messages_$_userId', list);
    await _chatBox.put('state_$_userId', jsonEncode(_conversationState.toJson()));
  }

  MindoUserContext _userContext() {
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
    return MindoUserContext(
      displayName: profile?.displayName ?? '',
      totalXp: profile?.totalXp ?? 0,
      currentStreak: profile?.currentStreak ?? 0,
      level: profile?.level ?? LevelType.seedling,
      daysOnJourney: days,
      moodEntriesCount: moods.length,
      loggedMoodToday: loggedToday,
      meditationSessions: 0,
    );
  }

  Future<void> _resetConversation() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Nova Conversa?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Deseja limpar todo o histórico do chat com o Mindo e começar uma nova conversa do zero?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final name = ref.read(userProfileNotifierProvider).value?.displayName ?? '';
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  role: 'assistant',
                  content: MindoEngine.welcomeMessage(name),
                  time: DateTime.now(),
                ));
                _conversationState = const MindoConversationState();
              });
              await _chatBox.delete('messages_$_userId');
              await _chatBox.delete('state_$_userId');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Histórico de conversa limpo.')),
              );
            },
            child: const Text('Nova Conversa', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: text,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();
    await _saveSession();
    ref.read(missionsProvider.notifier).onMindoMessageSent();
    final reply = _engine.respond(
      input: text,
      state: _conversationState,
      user: _userContext(),
    );
    final delayMs = 600 + (reply.text.length * 2).clamp(0, 2200);
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;
    await ref.read(userProfileNotifierProvider.notifier).addXp(8);
    setState(() {
      _isTyping = false;
      _conversationState = reply.state;
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: reply.text,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
    await _saveSession();
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
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
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            tooltip: 'Nova Conversa',
            onPressed: _resetConversation,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator();
                }
                return _MessageBubble(
                  message: _messages[index],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
              },
            ),
          ),
          // Sugestões rápidas (somente no início)
          if (_ready && _conversationState.userMessageCount == 0) _buildQuickSuggestions(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _ChatMessage {
  final String role;
  final String content;
  final DateTime time;
  _ChatMessage({required this.role, required this.content, required this.time});
  bool get isUser => role == 'user';
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
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
                gradient: message.isUser ? AppColors.gradientPrimary : null,
                color: message.isUser ? null : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                message.content,
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
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
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
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          // Send button
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
