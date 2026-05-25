import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientação preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Hive (armazenamento local)
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxUser);
  await Hive.openBox(AppConstants.hiveBoxMoods);
  await Hive.openBox(AppConstants.hiveBoxSettings);

  // Inicializar Serviço de Notificações
  final notificationService = NotificationService();
  await notificationService.initialize();
  final settingsBox = Hive.box(AppConstants.hiveBoxSettings);
  final notificationsEnabled = settingsBox.get('notifications_enabled', defaultValue: true) as bool;
  await notificationService.scheduleRepeatingReminders(enabled: notificationsEnabled);

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
