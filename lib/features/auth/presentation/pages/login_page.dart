import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _clearOfflineMode() async {
    try {
      final box = await Hive.openBox(AppConstants.hiveBoxSettings);
      await box.put('offline_mode', false);
    } catch (_) {}
  }

  Future<void> _enterOfflineMode() async {
    try {
      final box = await Hive.openBox(AppConstants.hiveBoxSettings);
      await box.put('offline_mode', true);
    } catch (_) {}
    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      await ref.read(userProfileNotifierProvider.future);
      if (mounted) context.go(AppRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final emailController = TextEditingController(text: 'seu.email.gmail@gmail.com');
        final nameController = TextEditingController(text: 'Viajante Emocional');
        bool isDialogLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.glassBorder),
              ),
              title: const Row(
                children: [
                  Text('🌐', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text(
                    'Gmail Google OAuth',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulação segura de login com conta Google para ambiente de testes e modo offline.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nome Google',
                      prefixIcon: Icon(Icons.person_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'E-mail Gmail',
                      prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (emailController.text.isEmpty || nameController.text.isEmpty) return;
                          setDialogState(() => isDialogLoading = true);
                          try {
                            await ref.read(authNotifierProvider.notifier).signInWithGoogleSimulated(
                                  emailController.text.trim(),
                                  nameController.text.trim(),
                                );
                            await ref.read(userProfileNotifierProvider.future);
                            if (mounted) {
                              Navigator.pop(context);
                              context.go(AppRoutes.dashboard);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          } finally {
                            setDialogState(() => isDialogLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Conectar Gmail'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('🧠', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Text(
                        'MindFlow',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'Bem-vindo\nde volta! 👋',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Sua jornada emocional continua aqui.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: AppSpacing.xxl),
                  // Form
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'seu@email.com',
                            prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Esqueceu a senha?'),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: AppSpacing.lg),
                  GradientButton(
                    label: 'Entrar',
                    isLoading: _isLoading,
                    onPressed: _signInWithEmail,
                  ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: AppSpacing.lg),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.glassBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'ou continue com',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.glassBorder)),
                    ],
                  ).animate(delay: 450.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.lg),
                  // Social logins
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          emoji: '🌐',
                          onTap: _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SocialButton(
                          label: 'Apple',
                          emoji: '🍎',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: AppSpacing.xxl),
                  // Register link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Não tem conta? ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: const Text(
                            'Criar agora',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 550.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.lg),
                  // Offline entry option
                  Center(
                    child: TextButton(
                      onPressed: _enterOfflineMode,
                      child: const Text(
                        'Acessar sem conta (modo offline) 🔌',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.glassBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
