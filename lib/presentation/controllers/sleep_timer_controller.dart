import 'dart:async';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

/// Uyku zamanlayıcısı.
///
/// Aşama 7 güncellemesi:
/// - [totalSeconds]: halka göstergesi için başlangıç toplamı (kalan/toplam
///   oranı gerçek ilerleme verir).
/// - [startTimer]'ın `fadeSeconds` parametresi: sönümleme penceresi artık
///   son 10 saniyeye sabit değil; 60-300 sn aralığında seçilebilir
///   (0 = sönümleme yok, süre dolunca doğrudan durur). Ses kanalı
///   davranışı aynen korunur: yalnızca oynatıcı sesi rampalanır.
class SleepTimerController extends GetxController {
  SleepTimerController();

  final PlayerController _player = Get.find<PlayerController>();

  final isActive = false.obs;
  final isEndOfTrackMode = false.obs;
  final remainingSeconds = 0.obs;
  final totalSeconds = 0.obs;

  /// Şu anki sönümleme penceresi (saniye). Sheet'e okunur; +5 dk uzatması
  /// aynı pencereyi korur.
  int _fadeSeconds = 10;
  int get fadeSeconds => _fadeSeconds;

  Timer? _timer;
  StreamSubscription? _playerStateSub;

  void startTimer(int minutes, {bool resetVolume = false, int? fadeSeconds}) {
    cancelTimer(resetVolume: resetVolume);
    if (fadeSeconds != null) _fadeSeconds = fadeSeconds;
    isActive.value = true;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = minutes * 60;
    totalSeconds.value = minutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        if (_fadeSeconds > 0 &&
            remainingSeconds.value <= _fadeSeconds) {
          final vol = remainingSeconds.value / _fadeSeconds;
          _player.setVolume(vol.clamp(0.0, 1.0));
        }
      } else {
        _timer?.cancel();
        _timer = null;
        _player.pause();
        _player.setVolume(1.0);
        isActive.value = false;
        isEndOfTrackMode.value = false;
        totalSeconds.value = 0;
      }
    });
  }

  void startEndOfTrack() {
    cancelTimer(resetVolume: true);
    _fadeSeconds = 0;
    isActive.value = true;
    isEndOfTrackMode.value = true;
    remainingSeconds.value = 0;
    totalSeconds.value = 0;

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
    totalSeconds.value = 0;
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
