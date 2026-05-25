import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../app/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../../../mood_tracker/providers/mood_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            name,
          );
      await ref.read(userProfileNotifierProvider.future);
      if (!mounted) return;
      final displayName = ref.read(userProfileNotifierProvider).value?.displayName ?? name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), $displayName! Sua jornada começa agora.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.dashboard);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Criar conta\ngratuita ✨',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Comece sua jornada emocional agora.',
                    style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: AppSpacing.xxl),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Como quer ser chamado(a)?',
                            hintText: 'Seu nome',
                            prefixIcon: Icon(Icons.person_rounded,
                                color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'seu@email.com',
                            prefixIcon: Icon(Icons.email_rounded,
                                color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Mínimo 8 caracteres',
                            prefixIcon: const Icon(Icons.lock_rounded,
                                color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: AppSpacing.lg),
                  GradientButton(
                    label: 'Criar conta 🚀',
                    isLoading: _isLoading,
                    onPressed: _register,
                  ).animate(delay: 300.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      'Ao criar conta, você concorda com nossos\nTermos de Uso e Política de Privacidade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ).animate(delay: 400.ms).fadeIn(),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Já tem conta? ',
                            style: TextStyle(color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 450.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
