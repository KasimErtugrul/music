import 'dart:async';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class SleepTimerController extends GetxController {
  final _player = Get.find<PlayerController>();

  final isActive = false.obs;
  final isEndOfTrackMode = false.obs;
  final remainingSeconds = 0.obs;

  Timer? _timer;
  StreamSubscription? _playerStateSub;

  void startTimer(int minutes, {bool resetVolume = false}) {
    cancelTimer(resetVolume: resetVolume);
    isActive.value = true;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = minutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        if (remainingSeconds.value <= 10) {
          final vol = remainingSeconds.value / 10.0;
          _player.setVolume(vol.clamp(0.0, 1.0));
        }
      } else {
        _timer?.cancel();
        _timer = null;
        _player.pause();
        _player.setVolume(1.0);
        isActive.value = false;
        isEndOfTrackMode.value = false;
      }
    });
  }

  void startEndOfTrack() {
    cancelTimer(resetVolume: true);
    isActive.value = true;
    isEndOfTrackMode.value = true;
    remainingSeconds.value = 0;

    bool hasPaused = false;

    Future<void> handleEnd() async {
      if (hasPaused) return;
      hasPaused = true;
      await _player.pause();
      _player.setVolume(1.0);
      isActive.value = false;
      isEndOfTrackMode.value = false;
      await _playerStateSub?.cancel();
      _playerStateSub = null;
    }

    // `PlayerController`'da `positionStream` getter'ı yok ama
    // `position` bir `Rx<Duration>` ve altında `_repository.positionStream`
    // dinleniyor. Aynı frekansta (200 ms) güncelleme alırız.
    _playerStateSub = _player.position.listen((pos) {
      if (!isEndOfTrackMode.value) return;
      final dur = _player.duration.value;
      if (dur.inMilliseconds <= 0) return;
      final remainingMs = dur.inMilliseconds - pos.inMilliseconds;
      if (remainingMs > 0 && remainingMs <= 300) {
        handleEnd();
      }
    });
  }

  void cancelTimer({bool resetVolume = true}) {
    _timer?.cancel();
    _timer = null;
    _playerStateSub?.cancel();
    _playerStateSub = null;
    isActive.value = false;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = 0;
    if (resetVolume) {
      _player.setVolume(1.0);
    }
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }
}