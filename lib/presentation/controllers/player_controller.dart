import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/models/queue_state_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';

class PlayerController extends GetxController {
  PlayerController(
    this._repository,
    this._libraryRepo,
    this._stateRepo,
    this._historyRepo,
  );

  final PlayerRepository _repository;
  final LibraryRepository _libraryRepo;
  final QueueStateRepository _stateRepo;
  final HistoryRepository _historyRepo;
  final prefCtrl = Get.find<PreferencesController>();

  final currentItem = Rxn<MediaItem>();
  final queue = <MediaItem>[].obs;
  final songQueue = <SongModel>[].obs;

  final isPlaying = false.obs;
  final processingState = AudioProcessingState.idle.obs;
  final shuffleEnabled = false.obs;
  final repeatMode = AudioServiceRepeatMode.none.obs;
  final lastError = Rxn<PlayerException>();

  // Ek-B: Oynatma hızı. playbackState'ten canlı beslenir; oynatıcı sayfasındaki
  // hız çipi artık sabit '1.0x' yerine bu değeri gösterir.
  final speed = 1.0.obs;

  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

   Stream<PlaybackState> get playbackStateStream => _repository.playbackStateStream;


  String? _loggedSongUri;
  bool _isRestoring = true;



  SongModel? get currentSong {
    final id = currentItem.value?.id;
    if (id == null) return null;
    // Aynı şarkı kuyrukta iki kez olsa bile doğru index'ten al
    final idx = _repository.currentIndex;
    if (idx == null || idx < 0 || idx >= songQueue.length) return null;
    return songQueue[idx];
  }

  @override
  void onInit() {
    super.onInit();
    _bind();
    _restoreQueue();
  }

  void _bind() {

    _repository.mediaItemStream.listen((item) {
      if (currentItem.value?.id != item?.id) {
        _loggedSongUri = null;
      }
      currentItem.value = item;
      if (!_isRestoring) _saveQueueState();
    });

    _repository.queueStream.listen((items) => queue.assignAll(items));

    _repository.playbackStateStream.listen((state) {
      isPlaying.value = state.playing;
      processingState.value = state.processingState;
      speed.value = state.speed; // Ek-B: hız çipi için canlı değer
      if (!_isRestoring &&
          (!state.playing ||
              state.processingState == AudioProcessingState.idle)) {
        _saveQueueState();
      }
    });

    _repository.errorStream.listen((error) => lastError.value = error);

    _repository.positionStream.listen((pos) {
      position.value = pos;
      _checkHistory(pos);
    });

    _repository.durationStream.listen((dur) {
      if (dur != null) duration.value = dur;
    });
  }

  void setVolume(double vol) => _repository.setVolume(vol);

    void _checkHistory(Duration pos) {
    final song = currentSong;
    if (song == null || _loggedSongUri == song.uri) return;

    // Harici dosyalar (id < 0) geçmişe yazılmaz
    if (song.id < 0) return;

    final minDuration = const Duration(seconds: 30);
    final halfDuration = Duration(milliseconds: song.durationMs ~/ 2);
    final threshold = minDuration < halfDuration ? minDuration : halfDuration;

    if (pos >= threshold) {
      _historyRepo.recordPlay(song);
      _loggedSongUri = song.uri;
    }
  }

  

  Future<void> fastForward() async {
    final sec = prefCtrl.playback.value.seekIntervalSeconds;
    final newPos = position.value + Duration(seconds: sec);
    await _repository.seek(newPos);
  }

  Future<void> rewind() async {
    final sec = prefCtrl.playback.value.seekIntervalSeconds;
    final newPos = position.value - Duration(seconds: sec);
    await _repository.seek(newPos.isNegative ? Duration.zero : newPos);
  }

  Future<void> _restoreQueue() async {
    try {
      final state = await _stateRepo.loadState();
      if (state != null && state.songUris.isNotEmpty) {
        // Kayıtlı state varsa onu yükle
        final allSongs = await _libraryRepo.songs();
        final songMap = {for (var s in allSongs) s.uri: s};

        final restored = <SongModel>[];
        for (final uri in state.songUris) {
          final song = songMap[uri];
          if (song != null) restored.add(song);
        }

        if (restored.isNotEmpty) {
          int safeIndex = state.currentIndex.clamp(0, restored.length - 1);
          songQueue.assignAll(restored);
          shuffleEnabled.value = state.shuffleEnabled;
          repeatMode.value = state.repeatMode;

          // Kayıtlı state'i uygula
          await _repository.setShuffleMode(state.shuffleEnabled);
          await _repository.setRepeatMode(state.repeatMode);
          await _repository.loadQueue(
            restored,
            initialIndex: safeIndex,
            initialPosition: state.position,
          );
          return;
        }
      }

      // Kayıtlı state yoksa veya boşsa Varsayılanları uygula
      final pref = prefCtrl.playback.value;
      await _repository.setShuffleMode(pref.defaultShuffle);
      await _repository.setRepeatMode(_mapRepeatMode(pref.defaultRepeat));
    } catch (_) {
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _saveQueueState() async {
    if (songQueue.isEmpty) {
      await _stateRepo.clearState();
      return;
    }
    try {
      await _stateRepo.saveState(
        QueueStateModel(
          songUris: songQueue.map((s) => s.uri).toList(),
          currentIndex: _repository.currentIndex ?? 0,
          position: _repository.position,
          shuffleEnabled: shuffleEnabled.value,
          repeatMode: repeatMode.value,
          shuffleOrder: null,
        ),
      );
    } catch (_) {}
  }

  AudioServiceRepeatMode _mapRepeatMode(int val) => switch (val) {
    1 => AudioServiceRepeatMode.all,
    2 => AudioServiceRepeatMode.one,
    _ => AudioServiceRepeatMode.none,
  };

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    // Varsayılanları uygula
    final pref = prefCtrl.playback.value;
    await _repository.setSpeed(pref.speed);
    await _repository.setPitch(pref.pitch);
    await _repository.setSkipSilenceEnabled(pref.skipSilence);
    // Gapless just_audio'da varsayılan olarak açıktır, kapatmak için kuyruk yönetimi gerekebilir.
    // just_audio'da gapless kapatma doğrudan bir API değil, setAudioSources ile ilgilidir.
    // Şimdilik sadece speed/pitch ve skipSilence bağlıyoruz.

    final list = queue ?? <SongModel>[song];
    final index = list.indexWhere((s) => s.id == song.id);

    songQueue.assignAll(list);
    await _repository.loadQueue(list, initialIndex: index < 0 ? 0 : index);
    await _repository.play();
  }

   Future<void> pause() => _repository.pause();
  Future<void> setSpeed(double speed) => _repository.setSpeed(speed);
  Future<void> setPitch(double pitch) => _repository.setPitch(pitch);



  Future<void> playNext(SongModel song) async {
    if (songQueue.isEmpty) {
      await playSong(song);
      return;
    }
    final nextIdx = (_repository.currentIndex ?? 0) + 1;
    songQueue.insert(nextIdx, song);
    await _repository.insertSong(nextIdx, song);
  }

  Future<void> addToQueue(SongModel song) async {
    if (songQueue.isEmpty) {
      await playSong(song);
      return;
    }
    songQueue.add(song);
    await _repository.insertSong(songQueue.length - 1, song);
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= songQueue.length) return;
    songQueue.removeAt(index);
    await _repository.removeSong(index);
    if (songQueue.isEmpty) await _repository.stop();
  }

  Future<void> clearQueue() async {
    songQueue.clear();
    await _repository.stop();
    await _stateRepo.clearState();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final song = songQueue.removeAt(oldIndex);
    songQueue.insert(newIndex, song);
    await _repository.moveSong(oldIndex, newIndex);
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value)
      await _repository.pause();
    else
      await _repository.play();
  }

  Future<void> seek(Duration pos) => _repository.seek(pos);
  Future<void> next() => _repository.skipToNext();
  Future<void> previous() => _repository.skipToPrevious();

  Future<void> toggleShuffle() async {
    final next = !shuffleEnabled.value;
    await _repository.setShuffleMode(next);
    shuffleEnabled.value = next;
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (repeatMode.value) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
      _ => AudioServiceRepeatMode.none,
    };
    await _repository.setRepeatMode(next);
    repeatMode.value = next;
  }

  void clearError() => lastError.value = null;
}
