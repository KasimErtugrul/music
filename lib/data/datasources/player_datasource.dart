import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:resonance/core/errors/app_exception.dart';

/// `just_audio`'nun ince sarmalayıcısı. Yalnızca oynatma motoruyla konuşur;
/// `audio_service`/`AudioHandler` bağlantısı bu sınıfın dışında kurulur.
class PlayerDataSource {
  PlayerDataSource({AudioPlayer? player})
      : _player = player ??
            AudioPlayer(
              // Bozuk/desteklenmeyen dosyada otomatik sonraki şarkıya geçiş.
              // just_audio 0.10.x'te DOĞRULANDI (constructor parametresi).
              maxSkipsOnError: 6,
            );

  final AudioPlayer _player;

  AudioPlayer get player => _player;

  // ---- Yükleme ----

  /// Kuyruğu yükler. `sources` boşsa `null` döner ve oynatma durumu temizlenir.
  Future<void> loadQueue(
    List<AudioSource> sources, {
    int initialIndex = 0,
  }) async {
    if (sources.isEmpty) {
      await _player.setAudioSources(const <AudioSource>[]);
      return;
    }
    final index = initialIndex.clamp(0, sources.length - 1);
    await _player.setAudioSources(sources, initialIndex: index);
  }

  // ---- Kontroller ----

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  // ---- Stream'ler ----

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  /// just_audio 0.10.x: hatalar artık `playbackEventStream.onError` değil,
  /// ayrı `errorStream` üzerinden dinlenir. DOĞRULANDI.
  Stream<PlayerException> get errorStream => _player.errorStream;

  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  bool get playing => _player.playing;
  int? get currentIndex => _player.currentIndex;
  Duration get position => _player.position;

  Future<void> dispose() => _player.dispose();
}