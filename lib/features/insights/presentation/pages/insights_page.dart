import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_InsightCardModel> insights = [
      _InsightCardModel(
        emoji: '🧠',
        category: 'Neurociência',
        title: 'Cortisol e Rotina Noturna',
        content:
            'Percebemos que seus picos de ansiedade ocorrem principalmente quando seu sono do dia anterior fica abaixo de 6h. A privação do sono aumenta a sensibilidade da amígdala ao estresse.',
        suggestion: 'Tente manter o celular fora da cama hoje à noite 30min antes de dormir.',
        color: AppColors.primary,
      ),
      _InsightCardModel(
        emoji: '💪',
        category: 'Terapia Cognitivo-Comportamental',
        title: 'Correlação: Exercício e Motivação',
        content:
            'Nos dias em que você registrou a caminhada diária concluída, sua taxa de sentimentos como "Motivação" e "Esperança" aumentou em 45% nas horas seguintes.',
        suggestion: 'Faça uma caminhada de 10 min mesmo se o ânimo estiver baixo. A ação precede a motivação!',
        color: AppColors.accentGreen,
      ),
      _InsightCardModel(
        emoji: '🌱',
        category: 'Mindfulness',
        title: 'Espiral Mental Evitada',
        content:
            'Nas últimas 2 semanas, você usou a respiração em 4 ocasiões de "Raiva" ou "Ansiedade alta" (acima de 7). Isso ajudou seu batimento cardíaco a normalizar mais rápido.',
        suggestion: 'Mantenha essa resposta de pausa consciente. Você está ensinando seu cérebro a se autorregular.',
        color: AppColors.accent,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text(
          'Insights e Análises',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner/Header Card
            _buildHeaderCard(),
            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Análises Inteligentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...insights.map((ins) => _buildInsightCard(ins)).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E351E), Color(0xFF1A1A2E)],
      ),
      child: const Row(
        children: [
          Text('✨', style: TextStyle(fontSize: 32)),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compreensão Dinâmica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mindo analisa suas correlações de hábitos com humor e traduz em neurociência prática.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInsightCard(_InsightCardModel ins) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        borderColor: ins.color.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ins.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ins.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ins.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ins.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ins.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              ins.content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sugerido para hoje:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ins.suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCardModel {
  final String emoji;
  final String category;
  final String title;
  final String content;
  final String suggestion;
  final Color color;

  _InsightCardModel({
    required this.emoji,
    required this.category,
    required this.title,
    required this.content,
    required this.suggestion,
    required this.color,
  });
}
