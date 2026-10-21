import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

class ResonanceAudioHandler extends BaseAudioHandler with SeekHandler {
  ResonanceAudioHandler({PlayerDataSource? source})
    : _source = source ?? PlayerDataSource() {
    _bindStreams();
  }

  final PlayerDataSource _source;

  AudioPlayer get _player => _source.player;

  /// Gün 8: pozisyon ve süre UI'da dar kapsamlı dinlenir.
  Stream<Duration> get positionStream => _source.positionStream;
  Stream<Duration?> get durationStream => _source.durationStream;
  Stream<PlayerException> get errorStream => _source.errorStream;

  bool get hasNext => _source.hasNext;
  bool get hasPrevious => _source.hasPrevious;

  void _bindStreams() {
    _source.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _source.currentIndexStream.listen((index) {
      if (index == null) return;
      final items = queue.value;
      if (index >= 0 && index < items.length) {
        mediaItem.add(items[index]);
      }
    });

    _source.errorStream.listen((e) {
      // Gün 11: PlayerController üzerinden UI'da yerelleştirilmiş mesaj.
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: const <MediaControl>[
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const <MediaAction>{MediaAction.seek},
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
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => LoopMode.all,
    };
    await _source.setLoopMode(mode);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Gün 21: "uygulama kapatılınca durdur" ayarı bağlanacak.
    await super.onTaskRemoved();
  }
}
