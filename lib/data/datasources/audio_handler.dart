import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

/// `audio_service` tarafından yönetilen arka plan oynatma köprüsü.
/// `PlayerDataSource`'ı sarar; kuyruk, medya öğesi ve playback durumunu
/// `audio_service`'e bildirir.
class ResonanceAudioHandler extends BaseAudioHandler with SeekHandler {
  ResonanceAudioHandler({PlayerDataSource? source})
      : _source = source ?? PlayerDataSource() {
    _bindStreams();
  }

  final PlayerDataSource _source;

  AudioPlayer get _player => _source.player;

  // ---- Başlangıç bağlantıları ----

  void _bindStreams() {
    // just_audio → audio_service playback state.
    _source.playbackEventStream
        .map(_transformEvent)
        .pipe(playbackState);

    // Mevcut kuyruk indeksi değiştiğinde MediaItem'ı güncelle.
    _source.currentIndexStream.listen((index) {
      if (index == null) return;
      final items = queue.value;
      if (index >= 0 && index < items.length) {
        mediaItem.add(items[index]);
      }
    });

    // Hatalar: `errorStream` (0.10.x). Otomatik atlama `maxSkipsOnError`
    // ile yapılıyor; burada yalnızca loglama/ileride UI bildirimi için
    // dinliyoruz.
    _source.errorStream.listen((e) {
      // Gün 8'de yerelleştirilmiş hata gösterimi eklenecek; şimdilik sessiz.
    });
  }

  /// `just_audio` `PlaybackEvent` → `audio_service` `PlaybackState`.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: const <MediaControl>[
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const <MediaAction>{
        MediaAction.seek,
      },
      // Bildirim kompakt görünümünde gösterilecek kontrol indeksleri.
      // (0=previous, 1=play, 2=pause, 3=next) → previous, play, next.
      androidCompactActionIndices: const <int>[0, 1, 3],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ---- Kuyruk ----

  /// Şarkı listesini kuyruğa yükler. `sources` sırası `items` sırasıyla
  /// aynı olmalıdır.
  Future<void> loadTracks({
    required List<MediaItem> items,
    required List<AudioSource> sources,
    int initialIndex = 0,
  }) async {
    queue.add(items);
    if (items.isEmpty) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(items[initialIndex.clamp(0, items.length - 1)]);
    await _source.loadQueue(sources, initialIndex: initialIndex);
  }

  // ---- AudioHandler API ----

  @override
  Future<void> play() => _source.play();

  @override
  Future<void> pause() => _source.pause();

  @override
  Future<void> stop() async {
    await _source.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _source.seek(position);

  @override
  Future<void> skipToNext() => _source.skipToNext();

  @override
  Future<void> skipToPrevious() => _source.skipToPrevious();

  @override
  Future<void> setSpeed(double speed) => _source.setSpeed(speed);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _source.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final mode = switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
    };
    await _source.setLoopMode(mode);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Uygulama son görevden kaldırıldığında varsayılan: çalmaya devam et.
    // Gün 21'de "uygulama kapatılınca durdur" ayarı eklenecek.
    await super.onTaskRemoved();
  }
}