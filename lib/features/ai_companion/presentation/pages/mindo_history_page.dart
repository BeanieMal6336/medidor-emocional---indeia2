import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/mindo_chat_provider.dart';
import '../../../../core/domain/entities/mindo_conversation.dart';

class MindoHistoryPage extends ConsumerWidget {
  /// Callback chamado quando o usuário seleciona uma conversa.
  final void Function(MindoConversation conversation) onSelect;

  /// Callback chamado quando o usuário quer iniciar uma nova conversa.
  final VoidCallback onNewConversation;

  const MindoHistoryPage({
    super.key,
    required this.onSelect,
    required this.onNewConversation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(mindoConversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Histórico de Conversas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton.icon(
              onPressed: onNewConversation,
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 18),
              label: const Text(
                'Nova',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Erro ao carregar histórico',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyState(onNewConversation: onNewConversation);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final conv = conversations[i];
              final isActive = conv.id == activeId;
              return _ConversationTile(
                conversation: conv,
                isActive: isActive,
                onTap: () => onSelect(conv),
                onDelete: () => _confirmDelete(context, ref, conv),
              ).animate().fadeIn(
                    duration: 250.ms,
                    delay: Duration(milliseconds: i * 40),
                  );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, MindoConversation conv) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Apagar conversa?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '"${conv.title}"\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(mindoConversationsProvider.notifier)
                  .deleteConversation(conv.id);
            },
            child: const Text('Apagar',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Tile de conversa ──────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final MindoConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(conversation.updatedAt);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // A deleção é gerenciada pelo onDelete
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primary.withOpacity(0.4) : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? AppColors.gradientPrimary
                      : const LinearGradient(
                          colors: [Color(0xFF2A2A3E), Color(0xFF1E1E2E)]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '🤖',
                    style: TextStyle(fontSize: isActive ? 22 : 18),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (conversation.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${conversation.messageCount} mensagem${conversation.messageCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ativa',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) {
      const weekdays = [
        'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
      ];
      return weekdays[date.weekday - 1];
    }
    return DateFormat('dd/MM/yy').format(date);
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewConversation;
  const _EmptyState({required this.onNewConversation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 36)),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Nenhuma conversa ainda',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Inicie uma conversa com o Mindo\npara que ela apareça aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: onNewConversation,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppColors.shadowPrimary,
              ),
              child: const Text(
                'Começar conversa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}
