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

  final currentItem = Rxn<MediaItem>();
  final queue = <MediaItem>[].obs;
  final songQueue = <SongModel>[].obs;

  final isPlaying = false.obs;
  final processingState = AudioProcessingState.idle.obs;
  final shuffleEnabled = false.obs;
  final repeatMode = AudioServiceRepeatMode.none.obs;
  final lastError = Rxn<PlayerException>();

  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  String? _loggedSongUri;

  SongModel? get currentSong {
    final id = currentItem.value?.id;
    if (id == null) return null;
    final idx = songQueue.indexWhere((s) => s.uri == id);
    return idx >= 0 ? songQueue[idx] : null;
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
        _loggedSongUri = null; // Şarkı değişti, geçmiş kaydı sıfırla
      }
      currentItem.value = item;
      _saveQueueState();
    });

    _repository.queueStream.listen((items) => queue.assignAll(items));

    _repository.playbackStateStream.listen((state) {
      isPlaying.value = state.playing;
      processingState.value = state.processingState;
      if (!state.playing || state.processingState == AudioProcessingState.idle) {
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

  void _checkHistory(Duration pos) {
    final song = currentSong;
    if (song == null || _loggedSongUri == song.uri) return;

    // Eşik: 30 saniye veya şarkının süresinin yarısı (hangisi daha küçükse)
    final minDuration = const Duration(seconds: 30);
    final halfDuration = Duration(milliseconds: song.durationMs ~/ 2);
    final threshold = minDuration < halfDuration ? minDuration : halfDuration;

    if (pos >= threshold) {
      _historyRepo.recordPlay(song.id);
      _loggedSongUri = song.uri;
    }
  }

  Future<void> _restoreQueue() async {
    try {
      final state = await _stateRepo.loadState();
      if (state == null || state.songUris.isEmpty) return;

      final allSongs = await _libraryRepo.songs();
      final songMap = {for (var s in allSongs) s.uri: s};

      final restored = <SongModel>[];
      for (final uri in state.songUris) {
        final song = songMap[uri];
        if (song != null) restored.add(song);
      }

      if (restored.isEmpty) {
        await _stateRepo.clearState();
        return;
      }

      int safeIndex = state.currentIndex.clamp(0, restored.length - 1);

      songQueue.assignAll(restored);
      shuffleEnabled.value = state.shuffleEnabled;
      repeatMode.value = state.repeatMode;

      await _repository.loadQueue(
        restored,
        initialIndex: safeIndex,
        initialPosition: state.position,
      );

      if (state.shuffleEnabled) {
        await _repository.setShuffleMode(true);
      }
    } catch (_) {}
  }

  Future<void> _saveQueueState() async {
    if (songQueue.isEmpty) {
      await _stateRepo.clearState();
      return;
    }
    try {
      await _stateRepo.saveState(QueueStateModel(
        songUris: songQueue.map((s) => s.uri).toList(),
        currentIndex: _getCurrentIndex(),
        position: _repository.position,
        shuffleEnabled: shuffleEnabled.value,
        repeatMode: repeatMode.value,
        shuffleOrder: null,
      ));
    } catch (_) {}
  }

  int _getCurrentIndex() {
    final id = currentItem.value?.id;
    if (id == null) return 0;
    final idx = songQueue.indexWhere((s) => s.uri == id);
    return idx < 0 ? 0 : idx;
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    final list = queue ?? <SongModel>[song];
    final index = list.indexWhere((s) => s.id == song.id);

    songQueue.assignAll(list);
    await _repository.loadQueue(list, initialIndex: index < 0 ? 0 : index);
    await _repository.play();
  }

  Future<void> _reloadQueue({int? newIndex, Duration? position}) async {
    if (songQueue.isEmpty) return;
    int targetIndex = newIndex ?? _getCurrentIndex();
    if (targetIndex < 0) targetIndex = 0;
    final targetPos = position ?? _repository.position;

    await _repository.loadQueue(
      songQueue,
      initialIndex: targetIndex,
      initialPosition: targetPos,
    );
  }

  Future<void> playNext(SongModel song) async {
    if (songQueue.isEmpty) {
      await playSong(song);
      return;
    }
    final currentIndex = _getCurrentIndex();
    songQueue.insert(currentIndex + 1, song);
    if (currentItem.value?.id == songQueue[currentIndex].uri) {
      await _reloadQueue(newIndex: currentIndex);
    }
  }

  Future<void> addToQueue(SongModel song) async {
    if (songQueue.isEmpty) {
      await playSong(song);
      return;
    }
    songQueue.add(song);
    if (currentItem.value != null) {
      await _reloadQueue(newIndex: _getCurrentIndex());
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= songQueue.length) return;
    final isCurrent = index == _getCurrentIndex();
    songQueue.removeAt(index);

    if (songQueue.isEmpty) {
      await _repository.stop();
    } else if (isCurrent) {
      await _reloadQueue(newIndex: index.clamp(0, songQueue.length - 1), position: Duration.zero);
    } else if (index < _getCurrentIndex()) {
      await _reloadQueue(newIndex: _getCurrentIndex() - 1);
    } else {
      await _reloadQueue(newIndex: _getCurrentIndex());
    }
  }

  Future<void> clearQueue() async {
    songQueue.clear();
    await _repository.stop();
    await _stateRepo.clearState();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final currentIdx = _getCurrentIndex();

    final song = songQueue.removeAt(oldIndex);
    songQueue.insert(newIndex, song);

    int targetIndex = currentIdx;
    if (oldIndex == currentIdx) {
      targetIndex = newIndex;
    } else if (oldIndex < currentIdx && newIndex >= currentIdx) {
      targetIndex -= 1;
    } else if (oldIndex > currentIdx && newIndex <= currentIdx) {
      targetIndex += 1;
    }

    await _reloadQueue(newIndex: targetIndex);
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
  }

  Future<void> seek(Duration position) => _repository.seek(position);
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