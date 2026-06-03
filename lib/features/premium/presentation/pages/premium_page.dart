import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/subscription_type.dart';
import '../../../../core/services/subscription_service.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  bool _loadingSilver = false;
  bool _loadingGold   = false;

  // ── Benefícios ────────────────────────────────────────────────────────────

  static const _silverBenefits = [
    _Benefit('📊', 'Relatórios Semanais', 'Gráficos detalhados da sua evolução emocional toda semana'),
    _Benefit('🎨', 'Temas Exclusivos', '6 temas visuais premium para personalizar o app'),
    _Benefit('🔔', 'Notificações Avançadas', 'Lembretes personalizados em horários escolhidos por você'),
    _Benefit('📝', 'Notas Ilimitadas', 'Escreva sem limite em cada registro de humor'),
    _Benefit('🗓️', 'Histórico Completo', 'Acesse todos os seus registros sem restrição de data'),
    _Benefit('🌙', 'Modo Noturno Pro', 'Interface AMOLED otimizada para escuridão total'),
  ];

  static const _goldBenefits = [
    _Benefit('🤖', 'IA Ilimitada com Mindo', 'Conversas sem limite com seu companheiro emocional IA'),
    _Benefit('🎤', 'Entrada por Voz', 'Registre seu humor falando — transcrição automática'),
    _Benefit('🧘', 'Meditações Guiadas Pro', '+50 sessões de meditação e respiração exclusivas'),
    _Benefit('🔮', 'Análise Preditiva', 'A IA detecta padrões e prevê dias difíceis antes de chegarem'),
    _Benefit('📤', 'Exportar para PDF/CSV', 'Compartilhe relatórios completos com terapeuta ou médico'),
    _Benefit('🏆', 'Missões Épicas Exclusivas', 'Desafios semanais com recompensas especiais de XP'),
    _Benefit('👨‍👩‍👧', 'Modo Família', 'Conecte até 3 perfis e acompanhe o bem-estar de quem você ama'),
    _Benefit('💎', 'Badge Gold Exclusiva', 'Exiba o crachá dourado no seu perfil — edição limitada'),
  ];

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentSub = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, currentSub),
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildComparisonTable()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _PlanCard(
                    type: SubscriptionType.silver,
                    benefits: _silverBenefits,
                    isActive: currentSub == SubscriptionType.silver,
                    isLoading: _loadingSilver,
                    onTap: () => _subscribe(SubscriptionType.silver),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    type: SubscriptionType.gold,
                    benefits: _goldBenefits,
                    isActive: currentSub == SubscriptionType.gold,
                    isLoading: _loadingGold,
                    onTap: () => _subscribe(SubscriptionType.gold),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildGuarantee()),
          SliverToBoxAdapter(child: _buildFaq()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context, SubscriptionType currentSub) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bgDark.withOpacity(0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: Row(
        children: [
          const Text('MindFlow ', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: _goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Premium',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        if (currentSub.isPremium)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: currentSub.isGold
                  ? const Color(0xFFFFD700).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentSub.isGold ? const Color(0xFFFFD700) : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              '${currentSub.emoji} Ativo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: currentSub.isGold ? const Color(0xFFFFD700) : Colors.grey[300],
              ),
            ),
          ),
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // Crown + glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _goldGradient,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 40, spreadRadius: 5),
                  ],
                ),
                child: const Center(
                  child: Text('👑', style: TextStyle(fontSize: 52)),
                ),
              ),
            ],
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => _goldGradient.createShader(bounds),
            child: const Text(
              'Desbloqueie seu\npotencial emocional',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 12),
          const Text(
            'Escolha o plano ideal e transforme\nsua saúde mental com IA e insights avançados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 20),
          // Social proof
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat('12.000+', 'usuários ativos'),
              _divider(),
              _buildStat('4.9 ⭐', 'na loja'),
              _divider(),
              _buildStat('97%', 'satisfação'),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ],
  );

  Widget _divider() => Container(
    height: 32, width: 1, color: AppColors.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 16),
  );

  // ── Comparison Table ──────────────────────────────────────────────────────

  Widget _buildComparisonTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            _tableHeader(),
            const Divider(height: 1, color: AppColors.glassBorder),
            _tableRow('Registro de humor', true, true, true),
            _tableRow('Mapa emocional', true, true, true),
            _tableRow('Missões diárias', true, true, true),
            _tableRow('Histórico (30 dias)', true, false, false),
            _tableRow('Histórico ilimitado', false, true, true),
            _tableRow('Relatórios semanais', false, true, true),
            _tableRow('Temas exclusivos', false, true, true),
            _tableRow('Notas ilimitadas', false, true, true),
            _tableRow('IA ilimitada', false, false, true),
            _tableRow('Meditações Pro (+50)', false, false, true),
            _tableRow('Análise preditiva IA', false, false, true),
            _tableRow('Exportar PDF/CSV', false, false, true),
            _tableRow('Modo Família (3 perfis)', false, false, true),
            _tableRow('Missões épicas exclusivas', false, false, true),
            _tableRow('Badge Gold exclusiva 💎', false, false, true),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: Text('Recurso', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
          _headerCell('🌱\nGratuito', Colors.grey),
          _headerCell('🥈\nSilver', const Color(0xFFC0C0C0)),
          _headerCell('👑\nGold', const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, Color color) => SizedBox(
    width: 60,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  Widget _tableRow(String label, bool free, bool silver, bool gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          _check(free, Colors.grey),
          _check(silver, const Color(0xFFC0C0C0)),
          _check(gold, const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _check(bool enabled, Color color) => SizedBox(
    width: 60,
    child: Center(
      child: enabled
          ? Icon(Icons.check_circle_rounded, color: color, size: 18)
          : const Icon(Icons.remove_rounded, color: AppColors.textDisabled, size: 16),
    ),
  );

  // ── Guarantee ────────────────────────────────────────────────────────────

  Widget _buildGuarantee() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Text('🛡️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Garantia de 7 dias', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text(
                    'Não ficou satisfeito? Devolvemos 100% do seu dinheiro. Sem burocracia.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ ──────────────────────────────────────────────────────────────────

  Widget _buildFaq() {
    const faqs = [
      _Faq('Quando serei cobrado?', 'A cobrança é feita no momento da assinatura e renovada automaticamente a cada 30 dias.'),
      _Faq('Posso cancelar a qualquer momento?', 'Sim! Cancele quando quiser pelas configurações do app. Você continua com acesso até o fim do período pago.'),
      _Faq('A IA do Mindo tem limite no Gold?', 'No plano Gold, o Mindo não tem limites de mensagens diárias. Converse à vontade!'),
      _Faq('O Silver vale a pena?', 'Com certeza! O Silver cobre todas as necessidades de acompanhamento emocional avançado. O Gold é para quem quer o máximo em análise e família.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perguntas Frequentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...faqs.map((faq) => _FaqTile(faq: faq)),
        ],
      ),
    );
  }

  // ── Subscribe Logic ───────────────────────────────────────────────────────

  Future<void> _subscribe(SubscriptionType type) async {
    if (type == SubscriptionType.silver) {
      setState(() => _loadingSilver = true);
    } else {
      setState(() => _loadingGold = true);
    }

    // Simula processamento de pagamento
    await Future.delayed(const Duration(milliseconds: 1800));
    await ref.read(subscriptionProvider.notifier).activate(type);

    if (mounted) {
      setState(() {
        _loadingSilver = false;
        _loadingGold   = false;
      });
      _showSuccessDialog(type);
    }
  }

  void _showSuccessDialog(SubscriptionType type) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type.isGold ? '👑' : '🥈',
                style: const TextStyle(fontSize: 64),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                'Bem-vindo ao ${type.label}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                type.isGold
                    ? 'Você desbloqueou o poder máximo do MindFlow. Sua jornada emocional nunca mais será a mesma! 💫'
                    : 'Seus relatórios, temas e histórico ilimitado já estão disponíveis! ✨',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: type.isGold ? const Color(0xFFFFD700) : const Color(0xFFC0C0C0),
                    foregroundColor: AppColors.bgDark,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (context.canPop()) context.pop();
                  },
                  child: const Text('Começar a usar!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlanCard
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubscriptionType type;
  final List<_Benefit> benefits;
  final bool isActive;
  final bool isLoading;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _PlanCard({
    required this.type,
    required this.benefits,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    this.isHighlighted = false,
  });

  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _silverGradient = LinearGradient(
    colors: [Color(0xFFE8E8E8), Color(0xFF9A9A9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final gradient = type.isGold ? _goldGradient : _silverGradient;
    final priceColor = type.isGold ? const Color(0xFFFFD700) : const Color(0xFFC0C0C0);
    final price = type.isGold ? 'R\$ 19,90' : 'R\$ 9,90';
    final label = type.label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? priceColor
              : (isHighlighted ? priceColor.withOpacity(0.5) : AppColors.glassBorder),
          width: isActive || isHighlighted ? 2 : 1,
        ),
        gradient: isHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgCard,
                  type.isGold
                      ? const Color(0xFFFFD700).withOpacity(0.06)
                      : const Color(0xFFC0C0C0).withOpacity(0.06),
                ],
              )
            : null,
        color: isHighlighted ? null : AppColors.bgCard,
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: priceColor.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge MAIS POPULAR (Gold)
            if (isHighlighted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: _goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🔥 MAIS POPULAR — MELHOR CUSTO-BENEFÍCIO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
              ),

            // Título
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => gradient.createShader(b),
                  child: Text(
                    type.emoji,
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => gradient.createShader(b),
                      child: Text(
                        'MindFlow $label',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    Text(
                      type.isGold ? 'Tudo incluso + IA ilimitada' : 'Relatórios + temas + mais',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: priceColor),
                    ),
                    const Text('/mês', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 12),

            // Lista de benefícios
            ...benefits.map((b) => _BenefitRow(benefit: b, color: priceColor)),
            const SizedBox(height: 20),

            // Botão
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: isActive ? null : gradient,
                  borderRadius: BorderRadius.circular(14),
                  border: isActive ? Border.all(color: priceColor, width: 2) : null,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isActive ? null : (isLoading ? null : onTap),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isActive ? '✓ Plano Ativo' : 'Assinar $label — $price/mês',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isActive ? priceColor : Colors.black87,
                          ),
                        ),
                ),
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Seu plano renova automaticamente a cada 30 dias',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted.withOpacity(0.7)),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: type.isGold ? 200.ms : 100.ms).slideY(begin: 0.1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BenefitRow
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;
  final Color color;

  const _BenefitRow({required this.benefit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(benefit.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(benefit.description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FaqTile
// ─────────────────────────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(faq.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        iconColor: AppColors.textMuted,
        collapsedIconColor: AppColors.textMuted,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(faq.answer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _Benefit {
  final String emoji;
  final String title;
  final String description;
  const _Benefit(this.emoji, this.title, this.description);
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}
