import 'dart:async';

import 'package:audio_service/audio_service.dart' show AudioProcessingState, AudioServiceRepeatMode;
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
///
/// FAZ 2 (K2): sönümleme artık bağımsız bir setVolume yazıcısı DEĞİL; ses
/// tek sahibi VolumeCoordinator'ın uyku sönümü katmanına yazar. Eskiden
/// her sönüm tıkı repository.setVolume'e gidiyordu: (a) aktif bir
/// oynat/duraklat rampasını iptal ediyor, (b) kullanıcının ses tercihini
/// ezerek _volumeTarget'i bozuyor, (c) süre dolunca sesi koşulsuz 1.0'a
/// zorluyordu. Katman modelinde sönüm kullanıcının tercihiyle ÇARPILIR;
/// süre dolunca tercih olduğu gibi geri gelir.
///
/// FAZ 3 (K8): sayaç mutlak deadline'a bağlandı. Eskiden kalan süre
/// tık-sayımlıydı (her tick'te `remainingSeconds--`): tık geciktiğinde
/// (meşgul olay döngüsü, Doze'da askıya alma) kalan süre GERÇEK duvar
/// saatinden sapardı ve sönüm çarpanı yanlış hızda indi. Artık bitiş anı
/// startTimer çağrısında DateTime olarak sabitlenir; her tık kalanı
/// saatten OKUR, tek atışlık bir zamanlayıcı da tam deadline anında
/// bitişi garanti eder. Testler için saat enjekte edilebilir.
class SleepTimerController extends GetxController {
  /// FAZ 3: saat enjeksiyonu — testler duvar saatini oynatabilir.
  SleepTimerController({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

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

  // --- FAZ 3: mutlak deadline ---------------------------------------------
  /// Bitiş anı (startTimer çağrısında sabitlenir; null: sayım yok).
  DateTime? _deadline;

  /// Tek atışlık zamanlayıcı: tıklar gecikse/askıya alınsa bile bitiş
  /// tam deadline anında tetiklenir.
  Timer? _deadlineTimer;

  /// FAZ 3: FAZ 2'deki end-of-track modunun tek aboneliği yerine olay
  /// seti (completed + parça değişimi + repeat-one sarmalama gözlemi).
  final List<StreamSubscription<dynamic>> _eotSubs = [];

  void startTimer(int minutes, {bool resetVolume = false, int? fadeSeconds}) {
    cancelTimer(resetVolume: resetVolume);
    if (fadeSeconds != null) _fadeSeconds = fadeSeconds;
    isActive.value = true;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = minutes * 60;
    totalSeconds.value = minutes * 60;

    // FAZ 3: kalanı SAYMAZ — bitiş anını sabitler, her tıkta saatten okur.
    _deadline = _now().add(Duration(minutes: minutes));
    _deadlineTimer = Timer(Duration(minutes: minutes), _finishByDeadline);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final remaining = deadline.difference(_now());
    if (remaining <= Duration.zero) {
      _finishByDeadline();
      return;
    }
    // Gösterim: yukarı yuvarla (t=0'da tam dakika görünür, t=1.0 sn'de
    // dakika-1) — eski sayaç gösterimiyle aynı algı, ama duvar saatinden.
    remainingSeconds.value = (remaining.inMilliseconds + 999) ~/ 1000;
    if (_fadeSeconds > 0 &&
        remaining.inMilliseconds <= _fadeSeconds * 1000) {
      // FAZ 3: sönüm çarpanı mutlak kalandan SÜREKLİ hesaplanır — tık
      // gecikse bile çarpan doğru hızda iner (tık sayımındaki zip gibi
      // sıçramalar yok).
      final vol =
          remaining.inMilliseconds / (_fadeSeconds * 1000);
      // FAZ 2: sönüm katmanı — setVolume DEĞİL. Kullanıcı sesiyle
      // çarpılır; aktif rampaları iptal etmez (K2 yarışının kökü kapandı).
      _player.setSleepDamping(vol.clamp(0.0, 1.0));
    }
  }

  /// FAZ 3: süre bitti — tek çıkış noktası (tık dalı ve tek atışlık
  /// zamanlayıcı aynı yolu kullanır; çift pause hasPaused tarzı
  /// _deadline=null nöbetiyle engellenir).
  void _finishByDeadline() {
    if (_deadline == null) return;
    _deadline = null;
    _timer?.cancel();
    _timer = null;
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    _player.pause();
    // FAZ 2: sesi 1.0'a ZORLAMAK yerine sönüm katmanı sıfırlanır;
    // kullanıcının kaydırıcı tercihi aynen kalır.
    _player.setSleepDamping(1.0);
    isActive.value = false;
    isEndOfTrackMode.value = false;
    totalSeconds.value = 0;
    remainingSeconds.value = 0;
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
      // FAZ 2: pause() rampa bitince döner; ardından sönüm katmanı
      // sıfırlanır (kullanıcı sesi 1.0'a zorlanmaz).
      await _player.pause();
      _player.setSleepDamping(1.0);
      isActive.value = false;
      isEndOfTrackMode.value = false;
      _cancelEotSubs();
    }

    // --- FAZ 3: parça sonu OLAY TABANLI (K8) --------------------------------
    // Eski yaklaşım konumu ~200 ms akışta yokluyor ve «remainingMs > 0 &&
    // <= 300» eşiğine bakıyordu. İki kör noktası vardı: (1) kuyruk sonunda
    // motor tamamlanınca kalan tam 0 olur — «> 0» şartı bu durumu KAÇIRIR;
    // (2) repeat-one'da parça sessizce başa sarar, akış eşiği yakalayabilir
    // de yakalamayabilir de (örnekleme yarışı). Artık üç olay kaynaklı
    // kanal vardır; konum yoklaması yalnızca repeat-one sarmalamasında
    // yedek olarak kullanılır.

    // Olay 1 — kuyruk sonu / tekrarsız bitiş: motor processingState=
    // completed yayınlar (audio_handler _mapProcessingState). «Kalan 0»
    // kör noktası ortadan kalkar.
    _eotSubs.add(_player.processingState.listen((state) {
      if (!isEndOfTrackMode.value || hasPaused) return;
      if (state == AudioProcessingState.completed) handleEnd();
    }));

    // Olay 2 — sırada sonraki parça / tekrar-tümü: currentItem değişimi
    // bir önceki parçanın BİTTİĞİNİN olay tabanlı kanıtıdır (motor zaten
    // sonrakine geçmiştir; gecikme yalnız olay iletimi kadardır).
    var lastItemId = _player.currentItem.value?.id;
    _eotSubs.add(_player.currentItem.listen((item) {
      if (!isEndOfTrackMode.value || hasPaused) return;
      final id = item?.id;
      if (id != null && id != lastItemId) handleEnd();
    }));

    // Repeat-one: parça başa sarar, completed/currentItem olayı HİÇ
    // GELMEZ. Sarmalama gözlemi: kalan ≤ 2 sn görüldükten sonra konum
    // başlangıca (≤ 2 sn) atlayırsa parça bittidir. Elle geri sarma
    // koruması: «yakın uç» ön koşulu olmadan atlama tetiklemez; ortadan
    // başa elle sarma bu koşulu geçmez.
    if (_player.repeatMode.value == AudioServiceRepeatMode.one) {
      var wasNearEnd = false;
      _eotSubs.add(_player.position.listen((pos) {
        if (!isEndOfTrackMode.value || hasPaused) return;
        final dur = _player.duration.value;
        if (dur.inMilliseconds <= 0) return;
        final remainingMs = dur.inMilliseconds - pos.inMilliseconds;
        if (remainingMs <= 2000) {
          // Yakın uç görüldü (eski hızlı yol da burası: kalan ≤ 300 ms
          // örneklenirse sarmalamadan HEMEN biter).
          if (remainingMs > 0 && remainingMs <= 300) handleEnd();
          wasNearEnd = true;
          return;
        }
        // Uzak konum: uçtan başa atlama yalnız burada yakalanır.
        if (wasNearEnd && pos.inMilliseconds <= 2000) handleEnd();
        wasNearEnd = false;
      }));
    }
  }

  void _cancelEotSubs() {
    for (final s in _eotSubs) {
      unawaited(s.cancel());
    }
    _eotSubs.clear();
  }

  void cancelTimer({bool resetVolume = true}) {
    _timer?.cancel();
    _timer = null;
    // FAZ 3: tek atışlık deadline zamanlayıcısı ve olay abonelikleri de
    // kapatılır (hijyen: onClose yolu dahil her iptalde kaynak sızması yok).
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    _deadline = null;
    _cancelEotSubs();
    isActive.value = false;
    isEndOfTrackMode.value = false;
    remainingSeconds.value = 0;
    totalSeconds.value = 0;
    if (resetVolume) {
      // FAZ 2: parametre adı (resetVolume) sözleşme uyumluluğu için korundu;
      // anlamı artık «sönüm katmanını sıfırla» — kullanıcı sesi ezilmez.
      _player.setSleepDamping(1.0);
    }
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }
}
