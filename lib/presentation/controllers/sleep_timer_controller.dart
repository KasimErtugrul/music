import 'dart:async';
import 'package:audio_service/audio_service.dart'; // EKLENDİ
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class SleepTimerController extends GetxController {
  final _player = Get.find<PlayerController>();
  
  final isActive = false.obs;
  final isEndOfTrackMode = false.obs;
  final remainingSeconds = 0.obs;

  Timer? _timer;
  StreamSubscription? _playerStateSub;

  void startTimer(int minutes) {
    cancelTimer();
    isActive.value = true;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = minutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        // Son 10 saniye kala sesi kıs (Fade out)
        if (remainingSeconds.value <= 10) {
          final vol = remainingSeconds.value / 10.0;
          _player.setVolume(vol);
        }
      } else {
        _player.pause();
        _player.setVolume(1.0); // Normale dön
        cancelTimer();
      }
    });
  }

  void startEndOfTrack() {
    cancelTimer();
    isActive.value = true;
    isEndOfTrackMode.value = true;
    remainingSeconds.value = 0;

    _playerStateSub = _player.playbackStateStream.listen((state) {
      if (state.processingState == AudioProcessingState.completed) {
        _player.pause();
        cancelTimer();
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _playerStateSub?.cancel();
    isActive.value = false;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = 0;
    _player.setVolume(1.0);
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }
}