import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

// ── Provider do SensorService ──────────────────────────────────────────────
final sensorServiceProvider = Provider<SensorService>((ref) => SensorService(ref));

class SensorService {
  final Ref _ref;
  late Box _sensorBox;
  
  // Streams e State
  StreamSubscription<StepCount>? _stepSubscription;
  int _todayBaseSteps = -1; // valor inicial do sensor ao reiniciar o dia
  int _todaySteps = 0;
  Position? _currentPosition;
  bool _isListeningSteps = false;

  SensorService(this._ref) {
    _init();
  }

  int get todaySteps => _todaySteps;
  Position? get currentPosition => _currentPosition;

  Future<void> _init() async {
    _sensorBox = await Hive.openBox('sensor_box');
    _todaySteps = _sensorBox.get(_todayStepsKey, defaultValue: 0) as int;
    
    // Inicia escuta silenciosa de passos e GPS (apenas em dispositivos móveis)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await initPedometer();
      await updateGPSLocation();
    }
  }

  String get _todayStepsKey {
    final now = DateTime.now();
    return 'steps_${now.year}_${now.month}_${now.day}';
  }

  // ── CONTAGEM DE PASSOS (PEDOMETER) ────────────────────────────────────────
  Future<void> initPedometer() async {
    if (kIsWeb || !defaultTargetPlatform.isMobile) {
      debugPrint('Pedometer não suportado nesta plataforma.');
      return;
    }

    try {
      // Pedir permissão de atividade física
      // Nota: o pacote pedometer cuida disso na inicialização do stream no Android/iOS
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        onDone: () => _isListeningSteps = false,
        cancelOnError: false,
      );
      _isListeningSteps = true;
    } catch (e) {
      debugPrint('Erro ao inicializar pedometer: $e');
    }
  }

  void _onStepCount(StepCount event) async {
    final now = DateTime.now();
    final todayKey = _todayStepsKey;
    
    // Pedometer retorna o total de passos desde o boot do aparelho.
    // Precisamos calibrar a base diária do dia atual.
    final savedBase = _sensorBox.get('${todayKey}_base', defaultValue: -1) as int;

    if (savedBase == -1) {
      // Primeira leitura de hoje, define os passos atuais do aparelho como a base de hoje
      _todayBaseSteps = event.steps;
      await _sensorBox.put('${todayKey}_base', event.steps);
      _todaySteps = 0;
    } else {
      _todayBaseSteps = savedBase;
      if (event.steps >= _todayBaseSteps) {
        _todaySteps = event.steps - _todayBaseSteps;
      } else {
        // Aparelho reiniciou, recalibra base
        _todayBaseSteps = event.steps;
        await _sensorBox.put('${todayKey}_base', event.steps);
        // Mantém passos anteriores salvos hoje
        _todaySteps = _sensorBox.get(todayKey, defaultValue: 0) as int;
      }
    }

    await _sensorBox.put(todayKey, _todaySteps);
    debugPrint('Passos de hoje atualizados: $_todaySteps');
  }

  void _onStepCountError(error) {
    debugPrint('Erro de leitura no Pedometer: $error');
    _isListeningSteps = false;
  }

  // Permite simular passos (útil para testes em Desktop/Emuladores)
  Future<void> simulateSteps(int count) async {
    _todaySteps += count;
    await _sensorBox.put(_todayStepsKey, _todaySteps);
  }

  // ── GPS E SEGURANÇA (GEOLOCATOR) ───────────────────────────────────────────
  Future<bool> checkLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> updateGPSLocation() async {
    try {
      final hasPermission = await checkLocationPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('GPS timeout'),
      );
      _currentPosition = position;
      return position;
    } catch (e) {
      debugPrint('Erro ao obter localização GPS: $e');
      return null;
    }
  }

  // Retorna os dados formatados para compartilhamento de emergência / segurança
  Future<String> getEmergencyMessage() async {
    final pos = await updateGPSLocation();
    if (pos == null) {
      return 'Alerta de Segurança MindFlow: Não foi possível obter as coordenadas GPS atuais. Por favor, verifique suas permissões.';
    }
    
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
    return '🚨 *Alerta de Segurança MindFlow* 🚨\n'
           'Estou compartilhando minha localização atual:\n'
           'Latitude: ${pos.latitude}\n'
           'Longitude: ${pos.longitude}\n'
           'Ver no Google Maps: $mapsUrl';
  }

  void dispose() {
    _stepSubscription?.cancel();
  }
}

extension PlatformDetection on TargetPlatform {
  bool get isMobile => this == TargetPlatform.iOS || this == TargetPlatform.android;
}
