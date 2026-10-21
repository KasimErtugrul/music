import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/player_repository.dart';

/// Kalıcı (`permanent: true`) oynatma controller'ı. Pozisyonu observable
/// yapmaz; UI pozisyonu `positionStream` ile dar kapsamlı dinler.
class PlayerController extends GetxController {
  PlayerController(this._repository);

  final PlayerRepository _repository;

  final currentItem = Rxn<MediaItem>();
  final queue = <MediaItem>[].obs;
  final isPlaying = false.obs;
  final processingState = AudioProcessingState.idle.obs;
  final shuffleEnabled = false.obs;
  final repeatMode = AudioServiceRepeatMode.none.obs;

  /// Gün 11: UI bunu `l10n` ile yerelleştirip gösterir.
  final lastError = Rxn<PlayerException>();

  @override
  void onInit() {
    super.onInit();
    _bind();
  }

  void _bind() {
    _repository.mediaItemStream.listen((item) => currentItem.value = item);
    _repository.queueStream.listen((items) => queue.assignAll(items));
    _repository.playbackStateStream.listen((state) {
      isPlaying.value = state.playing;
      processingState.value = state.processingState;
    });
    _repository.errorStream.listen((error) {
      lastError.value = error;
    });
  }

  /// Tek şarkı veya bir listeyi kuyruğa alıp çalar.
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    final list = queue ?? <SongModel>[song];
    final index = list.indexWhere((s) => s.id == song.id);
    await _repository.loadQueue(list, initialIndex: index < 0 ? 0 : index);
    await _repository.play();
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

  // UI'da dar kapsamlı Obx / StreamBuilder için.
  Stream<Duration> get positionStream => _repository.positionStream;
  Stream<Duration?> get durationStream => _repository.durationStream;
}