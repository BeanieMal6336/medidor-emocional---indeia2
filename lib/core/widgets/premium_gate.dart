import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../theme/app_colors.dart';
import '../domain/enums/subscription_type.dart';
import '../services/subscription_service.dart';

/// Wraps any widget and shows a premium upsell lock if the user
/// doesn't meet the required [requiredTier].
///
/// Usage:
/// ```dart
/// PremiumGate(
///   requiredTier: SubscriptionType.silver,
///   child: MyLockedWidget(),
/// )
/// ```
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final SubscriptionType requiredTier;
  final String? featureName;
  final String? featureDescription;

  const PremiumGate({
    super.key,
    required this.child,
    this.requiredTier = SubscriptionType.silver,
    this.featureName,
    this.featureDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    final bool hasAccess = requiredTier == SubscriptionType.gold
        ? sub.isGold
        : sub.isPremium;

    if (hasAccess) return child;

    return _PremiumLockOverlay(
      requiredTier: requiredTier,
      featureName: featureName ?? 'Recurso Premium',
      featureDescription: featureDescription ?? 'Este recurso está disponível no plano ${requiredTier.label}.',
      child: child,
    );
  }
}

class _PremiumLockOverlay extends StatelessWidget {
  final SubscriptionType requiredTier;
  final String featureName;
  final String featureDescription;
  final Widget child;

  const _PremiumLockOverlay({
    required this.requiredTier,
    required this.featureName,
    required this.featureDescription,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isGold = requiredTier == SubscriptionType.gold;
    final accentColor = isGold ? const Color(0xFFFFD700) : const Color(0xFFC0C0C0);

    return Stack(
      children: [
        // Blurred / dimmed preview of the actual content
        IgnorePointer(
          child: Opacity(opacity: 0.12, child: child),
        ),
        // Lock card
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.premium),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        isGold ? '👑' : '🥈',
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      featureName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      featureDescription,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isGold
                              ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                              : [const Color(0xFFE8E8E8), const Color(0xFF9A9A9A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Assinar ${requiredTier.label} — Desbloquear',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🛡️ Garantia de 7 dias — sem risco',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience method to show a bottom sheet upsell (for actions, not pages).
void showPremiumUpsell(
  BuildContext context, {
  String title = 'Recurso Premium',
  String description = 'Assine para desbloquear este recurso.',
  SubscriptionType requiredTier = SubscriptionType.silver,
}) {
  final isGold = requiredTier == SubscriptionType.gold;
  final accentColor = isGold ? const Color(0xFFFFD700) : const Color(0xFFC0C0C0);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(isGold ? '👑' : '🥈', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accentColor)),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: accentColor,
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.premium);
              },
              child: Text('Ver planos Premium', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não', style: TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
