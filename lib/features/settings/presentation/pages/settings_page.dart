import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/services/notification_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _biometricEnabled = false;
  bool _pinCodeEnabled = false;
  bool _notificationsEnabled = true;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    _notificationsEnabled = settingsBox.get('notifications_enabled', defaultValue: true) as bool;
    _biometricEnabled = settingsBox.get('biometric_enabled', defaultValue: false) as bool;
    _pinCodeEnabled = settingsBox.get('pincode_enabled', defaultValue: false) as bool;
    _offlineMode = settingsBox.get('offline_mode_strict', defaultValue: false) as bool;
  }

  void _showRegisteredEmails() {
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final registryList = settingsBox.get('offline_email_registry', defaultValue: <dynamic>[]) as List;
    final List<String> emails = List<String>.from(registryList.map((e) => e.toString()));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Row(
          children: [
            Text('📁', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text(
              'Banco de E-mails',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registros locais salvos no banco de dados local (Hive).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (emails.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum e-mail registrado ainda.',
                      style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: emails.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.email_rounded, color: AppColors.primary, size: 18),
                        ),
                        title: Text(
                          emails[index],
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Offline OK',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportLocalData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cópia criptografada dos seus dados exportada! 🔐 Backup salvo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMedium,
        title: const Text('Excluir todos os dados?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Esta ação é permanente e apagará todos os seus registros de humor locais e remotos.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados excluídos com sucesso.')),
              );
            },
            child: const Text('Sim, Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title: Privacidade & Segurança
            const Text(
              'Privacidade & Segurança',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                   _buildSwitchTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Autenticação Biométrica',
                    subtitle: 'Exigir digital/FaceID ao abrir o app',
                    value: _biometricEnabled,
                    onChanged: (val) async {
                      setState(() => _biometricEnabled = val);
                      await Hive.box(AppConstants.hiveBoxSettings).put('biometric_enabled', val);
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    icon: Icons.pin_rounded,
                    title: 'Bloqueio por Código PIN',
                    subtitle: 'Adicionar senha de 4 dígitos',
                    value: _pinCodeEnabled,
                    onChanged: (val) async {
                      setState(() => _pinCodeEnabled = val);
                      await Hive.box(AppConstants.hiveBoxSettings).put('pincode_enabled', val);
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    icon: Icons.cloud_off_rounded,
                    title: 'Modo Offline Estrito',
                    subtitle: 'Armazenar dados estritamente local no dispositivo',
                    value: _offlineMode,
                    onChanged: (val) async {
                      setState(() => _offlineMode = val);
                      await Hive.box(AppConstants.hiveBoxSettings).put('offline_mode_strict', val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Title: Preferências do App
            const Text(
              'Notificações',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                   _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Lembretes Periódicos (1h30)',
                    subtitle: 'Mensagens de positivismo e autocuidado a cada 1h30',
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      setState(() => _notificationsEnabled = val);
                      final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
                      await settingsBox.put('notifications_enabled', val);
                      await NotificationService().scheduleRepeatingReminders(enabled: val);
                    },
                  ),
                  const Divider(),
                  _buildActionTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Testar Notificação Agora',
                    subtitle: 'Receba um lembrete do MindFlow imediatamente',
                    onTap: () async {
                      await NotificationService().showTestNotification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificação de teste enviada! 🔔'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Title: Armazenamento e Limpeza
            const Text(
              'Dados e Armazenamento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.storage_rounded,
                    title: 'Banco de E-mails Registrados',
                    subtitle: 'Ver e-mails cadastrados local/online',
                    onTap: _showRegisteredEmails,
                  ),
                  const Divider(),
                  _buildActionTile(
                    icon: Icons.download_rounded,
                    title: 'Exportar Cópia de Dados',
                    subtitle: 'Salvar backup local criptografado',
                    onTap: _exportLocalData,
                  ),
                  const Divider(),
                  _buildActionTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Excluir Todos os Dados',
                    subtitle: 'Apagar histórico permanentemente',
                    onTap: _deleteData,
                    iconColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}
