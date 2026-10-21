import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/models/song_model.dart';

abstract class PlayerRepository {
  Stream<MediaItem?> get mediaItemStream;
  Stream<List<MediaItem>> get queueStream;
  Stream<PlaybackState> get playbackStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerException> get errorStream;

  Duration get position;

  Future<void> loadQueue(
    List<SongModel> songs, {
    int initialIndex = 0,
    Duration? initialPosition,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setShuffleMode(bool enabled);
  Future<void> setRepeatMode(AudioServiceRepeatMode mode);

  bool get hasNext;
  bool get hasPrevious;
}

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._handler);
  final ResonanceAudioHandler _handler;

  @override
  Stream<MediaItem?> get mediaItemStream => _handler.mediaItem;
  @override
  Stream<List<MediaItem>> get queueStream => _handler.queue;
  @override
  Stream<PlaybackState> get playbackStateStream => _handler.playbackState;
  @override
  Stream<Duration> get positionStream => _handler.positionStream;
  @override
  Stream<Duration?> get durationStream => _handler.durationStream;
  @override
  Stream<PlayerException> get errorStream => _handler.errorStream;
  @override
  Duration get position => _handler.position;

  @override
  Future<void> loadQueue(
    List<SongModel> songs, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    final items = <MediaItem>[for (final s in songs) _toMediaItem(s)];
    final sources = <AudioSource>[for (final s in songs) AudioSource.uri(Uri.parse(s.uri))];
    
    await _handler.loadTracks(
      items: items,
      sources: sources,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }

  MediaItem _toMediaItem(SongModel song) {
    return MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: _artUri(song),
    );
  }

  Uri? _artUri(SongModel song) {
    final albumId = song.albumId;
    if (albumId == null) return null;
    return Uri.parse('content://media/external/audio/albumart/$albumId');
  }

  @override
  Future<void> play() => _handler.play();
  @override
  Future<void> pause() => _handler.pause();
  @override
  Future<void> stop() => _handler.stop();
  @override
  Future<void> seek(Duration position) => _handler.seek(position);
  @override
  Future<void> skipToNext() => _handler.skipToNext();
  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  @override
  Future<void> setShuffleMode(bool enabled) => _handler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) => _handler.setRepeatMode(mode);
  @override
  bool get hasNext => _handler.hasNext;
  @override
  bool get hasPrevious => _handler.hasPrevious;
}