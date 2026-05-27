import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Orientação preferida — apenas em dispositivos móveis
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Status bar transparente (mobile only)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  // Hive (armazenamento local)
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxUser);
  await Hive.openBox(AppConstants.hiveBoxMoods);
  await Hive.openBox(AppConstants.hiveBoxSettings);

  // Inicializar Serviço de Notificações — apenas em plataformas suportadas
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
    final notificationsEnabled =
        settingsBox.get('notifications_enabled', defaultValue: true) as bool;
    await notificationService.scheduleRepeatingReminders(
        enabled: notificationsEnabled);
  }

  // Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MindFlowApp(),
    ),
  );
}
