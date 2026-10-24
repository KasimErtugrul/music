import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';

class PlayerDataSource {
  final AudioPlayer player;

  PlayerDataSource(AudioEffectsDatasource effects)
      : player = AudioPlayer(
          maxSkipsOnError: 6,
          audioPipeline: effects.pipeline,
        );

  Future<void> loadQueue(List<AudioSource> sources, {int initialIndex = 0, Duration? initialPosition}) async {
    if (sources.isEmpty) {
      await player.setAudioSources(const <AudioSource>[]);
      return;
    }
    final index = initialIndex.clamp(0, sources.length - 1);
    await player.setAudioSources(sources, initialIndex: index, initialPosition: initialPosition);
  }

  Future<void> insertSource(int index, AudioSource source) => player.insertAudioSource(index, source);
  Future<void> removeSource(int index) => player.removeAudioSourceAt(index);
  Future<void> moveSource(int from, int to) => player.moveAudioSource(from, to);

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> stop() => player.stop();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setSpeed(double speed) => player.setSpeed(speed);
  Future<void> setVolume(double volume) => player.setVolume(volume);
  Future<void> setLoopMode(LoopMode mode) => player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) => player.setShuffleModeEnabled(enabled);

  Future<void> skipToNext() async {
    if (player.hasNext) await player.seekToNext();
  }

  Future<void> skipToPrevious() async {
    if (player.hasPrevious) await player.seekToPrevious();
  }

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;
  Stream<PlaybackEvent> get playbackEventStream => player.playbackEventStream;
  Stream<PlayerException> get errorStream => player.errorStream;
  
  Stream<LoopMode> get loopModeStream => player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => player.shuffleModeEnabledStream;

  bool get hasNext => player.hasNext;
  bool get hasPrevious => player.hasPrevious;
  bool get playing => player.playing;
  int? get currentIndex => player.currentIndex;
  Duration get position => player.position;

  Future<void> dispose() => player.dispose();
}