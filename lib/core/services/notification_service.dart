import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço de notificações locais automáticas do MindFlow
/// Envia mensagens de positivismo, autocuidado e lembretes a cada 1h30
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'mindflow_reminders';
  static const _channelName = 'Lembretes MindFlow';
  static const _channelDesc = 'Mensagens motivacionais e de autocuidado';

  // ── Banco de mensagens ─────────────────────────────────────────────────────

  static const _positiveMessages = [
    '🌟 Você é mais forte do que pensa! O simples fato de estar aqui já é uma vitória.',
    '💜 Lembre-se: você merece cuidado e amor — especialmente o seu próprio.',
    '✨ Cada respiração é uma nova chance de começar. Respira fundo e sente isso.',
    '🌸 Você não precisa ser perfeito(a). Basta ser autêntico(a) e gentil consigo mesmo(a).',
    '🔥 Sua força interior é maior do que qualquer desafio que você enfrenta hoje.',
    '🌈 Depois de toda tempestade, o céu fica mais azul. Você vai passar por isso.',
    '💫 Hoje pode ser um dia difícil — mas você já passou por dias difíceis antes. E venceu.',
    '🦋 Crescimento acontece fora da zona de conforto. Você está evoluindo.',
    '🌻 Cada pequena conquista conta. Não ignore o progresso que você fez.',
    '❤️ Você importa. Sua presença faz diferença no mundo.',
  ];

  static const _selfCareMessages = [
    '💧 Já bebeu água hoje? Seu corpo e sua mente agradecem quando você se hidrata!',
    '🧘 Pause por 60 segundos. Feche os olhos. Respira. Você merece esse momento.',
    '🚶 Uma caminhada de 10 minutos pode mudar completamente seu humor. Que tal agora?',
    '😴 Já descansou hoje? O descanso não é preguiça — é necessidade.',
    '🍎 O que você comeu hoje? Nutrindo o corpo, você nutre também a mente.',
    '🛁 Cuide do seu corpo hoje. Um banho quente, uma música boa — momentos simples importam.',
    '📵 Que tal uma pausa das redes sociais agora? 15 minutos desconectado(a) fazem maravilhas.',
    '🌿 Respire o ar fresco hoje. Abra uma janela, sinta o vento. Reconecte-se com o mundo.',
    '💪 Alongue-se agora! 2 minutinhos para relaxar os ombros e o pescoço já fazem diferença.',
    '☕ Prepare algo quentinho e sente-se por um momento. Você merece uma pausa.',
  ];

  static const _reminderMessages = [
    '🧠 Como você está se sentindo agora? Registre no MindFlow — leva só 2 minutinhos!',
    '📝 Já fez seu registro de humor hoje? O Mindo está esperando para te ouvir! 💜',
    '🎯 Missão do dia: registrar como você está. Abra o MindFlow e cuide da sua mente!',
    '⏰ Hora do check-in emocional! Como você está agora? Vem registrar 😊',
    '🌙 No final do dia, como foi? Anote para não esquecer — memórias emocionais são preciosas.',
    '🌅 Começou o dia! Que tal registrar como está se sentindo logo no início?',
    '💬 O Mindo quer saber: você está bem? Vem conversar um pouco!',
  ];

  static const _affirmationMessages = [
    '🌟 Afirmação do dia: "Eu sou capaz de superar qualquer desafio com calma e determinação."',
    '💜 Afirmação: "Eu mereço paz, amor e todas as coisas boas da vida."',
    '✨ Afirmação: "Meu progresso pode ser lento, mas estou avançando todos os dias."',
    '🌸 Afirmação: "Eu escolho me tratar com a mesma gentileza que trataria meu melhor amigo."',
    '🔥 Afirmação: "Eu tenho tudo o que preciso dentro de mim para enfrentar este momento."',
    '🌈 Afirmação: "Minha saúde mental é uma prioridade — e tudo bem cuidar de mim."',
    '💫 Afirmação: "Cada dia é um presente e uma oportunidade de ser quem eu quero ser."',
  ];

  static const _breathingMessages = [
    '🫁 Técnica rápida: inspira 4 segundos, segura 4, expira 4. Repita 4 vezes. Simples e poderoso!',
    '🧘 Pausa de 60 segundos: feche os olhos e respire fundo 5 vezes. Seu sistema nervoso agradece.',
    '🌬️ Respire: 4 segundos de ar, 7 segurando, 8 soltando. A técnica 4-7-8 acalma em minutos.',
    '💨 Um minuto de respiração consciente pode reduzir o estresse em até 30%. Tente agora!',
    '🌊 Imagine uma onda indo e voltando com cada respiração. Inspire... expire... você está seguro(a).',
  ];

  static const _energyMessages = [
    '⚡ Você tem energia para hoje! Acredita em si mesmo(a) e vá em frente.',
    '🏃 Levanta, sacode a poeira e vai! Você é capaz de mais do que imagina.',
    '🌞 Bom dia, bom dia, bom dia! O universo conspirou para você estar aqui hoje.',
    '🎵 Coloque uma música boa e deixe ela carregar sua energia por uns minutinhos!',
    '🚀 Hoje é o dia! Que pequeno passo você pode dar para se aproximar do que ama?',
    '💃 Dance por 2 minutos. Parece bobo, mas funciona. Movimento gera energia!',
    '🎯 Foco: qual é a UMA coisa mais importante que você pode fazer hoje?',
  ];

  final _random = Random();

  // ── Inicialização ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Ao tocar na notificação, o app abre normalmente
      },
    );

    // Cria o canal Android
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
        ));
  }

  // ── Agendar notificações a cada 1h30 ─────────────────────────────────────

  Future<void> scheduleRepeatingReminders({bool enabled = true}) async {
    // Cancela todas as notificações existentes antes de reagendar
    await _plugin.cancelAll();

    if (!enabled) return;

    final settingsBox = Hive.box('settings_box');
    final silentStart = settingsBox.get('silent_start_hour', defaultValue: 23) as int;
    final silentEnd = settingsBox.get('silent_end_hour', defaultValue: 7) as int;

    final now = DateTime.now();

    // Agenda 20 notificações ao longo de 30 horas (a cada 90 min)
    for (int i = 0; i < 20; i++) {
      final scheduledTime = now.add(Duration(minutes: 90 * (i + 1)));
      final hour = scheduledTime.hour;

      // Pula horário silencioso (ex: 23h a 7h)
      final inSilentPeriod = silentStart > silentEnd
          ? hour >= silentStart || hour < silentEnd
          : hour >= silentStart && hour < silentEnd;

      if (inSilentPeriod) continue;

      final message = _getRandomMessage();

      await _plugin.zonedSchedule(
        i + 100,
        message['title']!,
        message['body']!,
        _toTZDateTime(scheduledTime),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(message['body']!),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ── Notificação de teste imediata ─────────────────────────────────────────

  Future<void> showTestNotification() async {
    final msg = _getRandomMessage();
    await _plugin.show(
      999,
      msg['title']!,
      msg['body']!,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _getRandomMessage() {
    final allCategories = [
      _positiveMessages,
      _selfCareMessages,
      _reminderMessages,
      _affirmationMessages,
      _breathingMessages,
      _energyMessages,
    ];

    final category = allCategories[_random.nextInt(allCategories.length)];
    final body = category[_random.nextInt(category.length)];

    final titles = [
      '💜 MindFlow — Mensagem pra você',
      '🧠 Momento de autocuidado',
      '🌟 MindFlow lembra: você importa',
      '✨ Uma pausa para sua mente',
      '🌸 MindFlow: lembrete do coração',
    ];

    return {
      'title': titles[_random.nextInt(titles.length)],
      'body': body,
    };
  }

  // TZDateTime helper — converte DateTime local para TZDateTime do timezone package
  tz.TZDateTime _toTZDateTime(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }
}
