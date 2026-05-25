import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider global do serviço de áudio ────────────────────────────────────
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Estado do player ────────────────────────────────────────────────────────
class AudioPlayerState {
  final bool isPlaying;
  final String? currentTrackId;
  final String? currentTrackName;
  final String? currentTrackEmoji;
  final double volume;
  final int? timerMinutes; // timer de sono

  const AudioPlayerState({
    this.isPlaying = false,
    this.currentTrackId,
    this.currentTrackName,
    this.currentTrackEmoji,
    this.volume = 0.7,
    this.timerMinutes,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    String? currentTrackId,
    String? currentTrackName,
    String? currentTrackEmoji,
    double? volume,
    int? timerMinutes,
    bool clearTimer = false,
  }) =>
      AudioPlayerState(
        isPlaying: isPlaying ?? this.isPlaying,
        currentTrackId: currentTrackId ?? this.currentTrackId,
        currentTrackName: currentTrackName ?? this.currentTrackName,
        currentTrackEmoji: currentTrackEmoji ?? this.currentTrackEmoji,
        volume: volume ?? this.volume,
        timerMinutes: clearTimer ? null : timerMinutes ?? this.timerMinutes,
      );
}

final audioPlayerStateProvider =
    StateNotifierProvider<AudioStateNotifier, AudioPlayerState>(
  (ref) => AudioStateNotifier(ref.read(audioServiceProvider)),
);

class AudioStateNotifier extends StateNotifier<AudioPlayerState> {
  final AudioService _service;
  Timer? _sleepTimer;

  AudioStateNotifier(this._service) : super(const AudioPlayerState());

  Future<void> play(RelaxationTrack track) async {
    await _service.play(track.url, volume: state.volume);
    state = state.copyWith(
      isPlaying: true,
      currentTrackId: track.id,
      currentTrackName: track.name,
      currentTrackEmoji: track.emoji,
    );
  }

  Future<void> pause() async {
    await _service.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resume() async {
    await _service.resume();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    await _service.stop();
    state = const AudioPlayerState();
  }

  void setTimer(int? minutes) {
    _sleepTimer?.cancel();
    if (minutes == null) {
      state = state.copyWith(clearTimer: true);
      return;
    }
    state = state.copyWith(timerMinutes: minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      stop();
    });
  }

  Future<void> setVolume(double vol) async {
    await _service.setVolume(vol);
    state = state.copyWith(volume: vol);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      resume();
    }
  }
}

// ── Serviço de áudio ───────────────────────────────────────────────────────
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url, {double volume = 0.7}) async {
    await _player.stop();
    await _player.setVolume(volume);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(UrlSource(url));
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> stop() => _player.stop();
  Future<void> setVolume(double vol) => _player.setVolume(vol);

  void dispose() {
    _player.dispose();
  }
}

// ── Catálogo de faixas de relaxamento ──────────────────────────────────────
class RelaxationTrack {
  final String id;
  final String name;
  final String emoji;
  final String url;
  final String description;
  final String category;

  const RelaxationTrack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.url,
    required this.description,
    required this.category,
  });
}

const relaxationTracks = [
  RelaxationTrack(
    id: 'rain',
    name: 'Chuva Suave',
    emoji: '🌧️',
    url: 'https://assets.mixkit.co/music/preview/mixkit-rain-and-thunder-ambient-sounds-2390.mp3',
    description: 'Som de chuva suave para acalmar a mente',
    category: 'Natureza',
  ),
  RelaxationTrack(
    id: 'ocean',
    name: 'Ondas do Mar',
    emoji: '🌊',
    url: 'https://assets.mixkit.co/music/preview/mixkit-relaxing-in-nature-522.mp3',
    description: 'Ondas do oceano para meditação profunda',
    category: 'Natureza',
  ),
  RelaxationTrack(
    id: 'forest',
    name: 'Floresta Viva',
    emoji: '🌲',
    url: 'https://assets.mixkit.co/music/preview/mixkit-forest-treasures-315.mp3',
    description: 'Pássaros e brisa na floresta',
    category: 'Natureza',
  ),
  RelaxationTrack(
    id: 'lofi',
    name: 'Lo-Fi Calmo',
    emoji: '🎵',
    url: 'https://assets.mixkit.co/music/preview/mixkit-slow-motion-1012.mp3',
    description: 'Beats Lo-Fi suaves para foco e relaxamento',
    category: 'Música',
  ),
  RelaxationTrack(
    id: 'tibetan',
    name: 'Tigelas Tibetanas',
    emoji: '🕉️',
    url: 'https://assets.mixkit.co/music/preview/mixkit-meditation-zen-ambiance-music-575.mp3',
    description: 'Sons de tigelas tibetanas para meditação',
    category: 'Meditação',
  ),
  RelaxationTrack(
    id: 'piano',
    name: 'Piano Suave',
    emoji: '🎹',
    url: 'https://assets.mixkit.co/music/preview/mixkit-dreaming-big-31.mp3',
    description: 'Piano melódico e tranquilo para relaxar',
    category: 'Música',
  ),
  RelaxationTrack(
    id: 'fire',
    name: 'Lareira Aconchegante',
    emoji: '🔥',
    url: 'https://assets.mixkit.co/music/preview/mixkit-campfire-crackles-1330.mp3',
    description: 'Crepitar do fogo para noites aconchegantes',
    category: 'Ambiente',
  ),
  RelaxationTrack(
    id: 'wind',
    name: 'Vento Suave',
    emoji: '🍃',
    url: 'https://assets.mixkit.co/music/preview/mixkit-light-rain-ambience-2781.mp3',
    description: 'Brisa suave para clareza mental',
    category: 'Natureza',
  ),
  RelaxationTrack(
    id: 'spa',
    name: 'Spa Relaxante',
    emoji: '🛁',
    url: 'https://assets.mixkit.co/music/preview/mixkit-spa-relaxation-music-557.mp3',
    description: 'Música de spa para corpo e mente',
    category: 'Meditação',
  ),
];
