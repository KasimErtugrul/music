import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:resonance/data/datasources/audio_session_datasource.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

class ResonanceAudioHandler extends BaseAudioHandler with SeekHandler {
  ResonanceAudioHandler({
    PlayerDataSource? source,
    required this._artResolver, // Lint düzeltmesi (initializing formal)
  }) : _source = source ?? PlayerDataSource() {
    AudioSessionDatasource(_source).init();
    _bindStreams();
  }

  final PlayerDataSource _source;
  final Future<Uri?> Function(String songUri) _artResolver;
  AudioPlayer get _player => _source.player;

  Stream<Duration> get positionStream => _source.positionStream;
  Stream<Duration?> get durationStream => _source.durationStream;
  Stream<PlayerException> get errorStream => _source.errorStream;
  Duration get position => _source.position;
  int? get currentIndex => _source.currentIndex;
  bool get hasNext => _source.hasNext;
  bool get hasPrevious => _source.hasPrevious;

  void _bindStreams() {
    // Tembel Kapak Yükleme
    _source.currentIndexStream.listen((index) async {
      if (index == null) return;
      final items = queue.value;
      if (index >= 0 && index < items.length) {
        final item = items[index];
        mediaItem.add(item); // Önce kapağı olmadan hemen göster
        
        final artUri = await _artResolver(item.id);
        // Hala aynı şarkı çalıyorsa kapağı güncelle
        if (artUri != null && mediaItem.value?.id == item.id) {
          mediaItem.add(item.copyWith(artUri: artUri));
        }
      }
    });

    // Tip hatasını çözmek için cast<PlaybackEvent> kullanıldı
    Rx.merge([
      _source.playbackEventStream,
      _source.loopModeStream.switchMap((_) => _source.playbackEventStream),
      _source.shuffleModeEnabledStream.switchMap((_) => _source.playbackEventStream),
    ]).cast<PlaybackEvent>().listen((event) {
      playbackState.add(_transformEvent(event));
    });

    _source.errorStream.listen((e) {});
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      _player.playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];

    final repeatMode = switch (_player.loopMode) {
      LoopMode.off => AudioServiceRepeatMode.none,
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
    };
    final shuffleMode = _player.shuffleModeEnabled 
        ? AudioServiceShuffleMode.all 
        : AudioServiceShuffleMode.none;

    return PlaybackState(
      controls: controls,
      systemActions: const {MediaAction.seek, MediaAction.skipToNext, MediaAction.skipToPrevious},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      repeatMode: repeatMode,
      shuffleMode: shuffleMode,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  Future<void> loadTracks({required List<MediaItem> items, required List<AudioSource> sources, int initialIndex = 0, Duration? initialPosition}) async {
    queue.add(items);
    if (items.isEmpty) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(items[initialIndex.clamp(0, items.length - 1)]);
    await _source.loadQueue(sources, initialIndex: initialIndex, initialPosition: initialPosition);
  }

  // Kuyruk API'leri (Önce listeyi güncelle, sonra player'ı)
  Future<void> insertTrack(int index, MediaItem item, AudioSource source) async {
    final newQueue = queue.value.toList()..insert(index, item);
    queue.add(newQueue);
    await _source.insertSource(index, source);
  }

  Future<void> removeTrack(int index) async {
    final newQueue = queue.value.toList()..removeAt(index);
    queue.add(newQueue);
    await _source.removeSource(index);
  }

  Future<void> moveTrack(int from, int to) async {
    final newQueue = queue.value.toList();
    final item = newQueue.removeAt(from);
    newQueue.insert(to, item);
    queue.add(newQueue);
    await _source.moveSource(from, to);
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
    await _source.setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
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
}