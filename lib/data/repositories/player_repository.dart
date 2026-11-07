import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/datasources/volume_coordinator.dart';
import 'package:resonance/data/models/song_model.dart';

abstract class PlayerRepository {
  Stream<MediaItem?> get mediaItemStream;
  Stream<List<MediaItem>> get queueStream;
  Stream<PlaybackState> get playbackStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerException> get errorStream;
  Duration get position;
  int? get currentIndex;

  Future<void> loadQueue(List<SongModel> songs, {int initialIndex = 0, Duration? initialPosition});
  Future<void> insertSong(int index, SongModel song);
  Future<void> removeSong(int index);
  Future<void> moveSong(int from, int to);

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();

  /// Bulgu 3: kuyruk sırasını yeniden kurmadan verilen indisteki parçaya
  /// geçer (karıştırma/tekrar durumu korunur). Somut gövdeli üye: yalnız
  /// PlayerRepositoryImpl uygular; test sahteleri bozulmaz.
  Future<void> skipToIndex(int index) async {}
  Future<void> setShuffleMode(bool enabled);
  Future<void> setRepeatMode(AudioServiceRepeatMode mode);

  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setPitch(double pitch);
  Future<void> setSkipSilenceEnabled(bool enabled);

  /// Gün 20: oynat/duraklat yumuşatma (fade) süresi. Duration.zero =
  /// kapalı (davranış eskisi gibi anlıktır). Somut gövdeli bir üyedir:
  /// yalnız PlayerRepositoryImpl uygular; test sahteleri ve Mock'lar
  /// (noSuchMethod) bu üyeyi uygulamak zorunda kalmaz.
  void setFadeDuration(Duration duration) {}

  /// FAZ 2: uyku zamanlayıcısı sönüm katmanı (0.0–1.0). Kullanıcı sesini
  /// EZMEZ — ses tek sahibi VolumeCoordinator'da kullanıcı sesiyle
  /// çarpılır. 1.0 = sönüm yok. Somut gövdeli üye: [setFadeDuration] ile
  /// aynı gerekçe (test sahteleri bozulmaz).
  void setSleepDamping(double factor) {}

  bool get hasNext;
  bool get hasPrevious;
}

class PlayerRepositoryImpl implements PlayerRepository {
  /// FAZ 2 (K1): tek sahiplik — gerçek kablolamada handler'ın
  /// koordinatörü devralınır (duck yolu da aynı örnekten beslenir).
  /// Test mock'ları [ResonanceAudioHandler.volumeCoordinator] üyesini
  /// bilmez (null döner); o zaman depo kendi örneğini kurar ve yazımlar
  /// handler.setVolume üzerinden akar — mevcut test doğrulamaları
  /// bozulmaz.
  PlayerRepositoryImpl(this._handler, {VolumeCoordinator? volumeCoordinator}) {
    final dynamic handlerOwned = _handler.volumeCoordinator;
    _volume = volumeCoordinator ??
        (handlerOwned is VolumeCoordinator ? handlerOwned : null) ??
        VolumeCoordinator(writeVolume: (v) => _handler.setVolume(v));
  }
  final ResonanceAudioHandler _handler;

  /// Sesin tek sahibi: katmanlar burada toplanır, motora tek yazımla
  /// çarpım gider. Adı [volumeCoordinator] ile karışmasın diye _volume.
  late final VolumeCoordinator _volume;

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
  int? get currentIndex => _handler.currentIndex;

  // --- Gün 20 + FAZ 2: yumuşatma (fade) -----------------------------------
  // Oynat/duraklat sesi [_fadeSteps] adımda hedefe taşır; yazılan değer
  // koordinatörün katman çarpımıdır (kullanıcı sesi × rampa × duck ×
  // uyku sönümü). Kullanıcı fade sırasında sesi değiştirirse (setVolume)
  // rampa iptal edilir ve kullanıcı devralır (eski sözleşme). Jenerasyon
  // sayacı, iptal edilmiş bir rampanın son tıkının geç yazmasını
  // engeller. FAZ 2: pause() ARTIK rampa BİTİNCE döner (Completer);
  // rampa bu arada iptal edilirse Future yine tamamlanır (asılı await
  // yok), yalnız beklemedeki pause atlanır.
  static const int _fadeSteps = 20;

  Timer? _fadeTimer;
  int _fadeGeneration = 0;
  Duration _fadeDuration = Duration.zero;

  /// Aktif rampanın tamamlanma Future'ı: [_cancelRamp] iptal anında
  /// bekleyenleri uyandırır (supersede edilen pause asılı kalmaz).
  Completer<void>? _activeRampDone;

  /// Son bilinen çalma durumu. Kulaklık çıkarmada duraklatma, ses akışı
  /// katmanında (AudioSessionDatasource) yapıldığı için depoyu geçmez;
  /// o yolda [_assumedPlaying] true kalır ve sonraki play() rampasız
  /// çalar — ses zaten hedefte olduğundan tutarlıdır.
  bool _assumedPlaying = false;

  @override
  void setFadeDuration(Duration duration) {
    _fadeDuration = duration;
  }

  void _cancelRamp() {
    _fadeGeneration++;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    // İptal edilen rampanın Future'ı hemen tamamlanır: await eden (FAZ 2
    // ile rampa bitince dönen pause) asılı kalmaz; «then» eylemi zaten
    // jenerasyon korumasıyla atlanır.
    final done = _activeRampDone;
    _activeRampDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  /// Rampayı çarpan katmanı üzerinden yürütür: [from] → [to] rampa
  /// çarpanı (0.0–1.0), motora yazılan değer katman çarpımıdır. Başlangıçta
  /// [from] hemen yazılır (ilk adım aralığı eski sesle çalınmasın); bitişte
  /// tam [to] yazılır, ardından [then] çalışır (fade-out sonunda pause
  /// gibi). Dönen Future FAZ 2 sözleşmesidir: rampa bitince (veya iptal
  /// edilince) tamamlanır; [then] hatası arayana iletilir.
  Future<void> _rampVolume(double from, double to, Future<void> Function()? then) {
    final gen = ++_fadeGeneration;
    final done = Completer<void>();
    _activeRampDone = done;
    unawaited(_volume.setRampFactor(from));
    final stepGap = Duration(
      microseconds: _fadeDuration.inMicroseconds ~/ _fadeSteps,
    );
    var step = 0;
    _fadeTimer = Timer.periodic(stepGap, (timer) async {
      if (gen != _fadeGeneration) {
        // İptal edildi: Future zaten _cancelRamp'ta tamamlandı.
        timer.cancel();
        return;
      }
      step++;
      if (step >= _fadeSteps) {
        timer.cancel();
        _fadeTimer = null;
        try {
          await _volume.setRampFactor(to);
          if (gen != _fadeGeneration) {
            // Son yazım bu arada iptal olduysa son eylemi atla.
            if (!done.isCompleted) done.complete();
            return;
          }
          await then?.call();
          if (!done.isCompleted) done.complete();
        } on Object catch (e, s) {
          if (!done.isCompleted) {
            done.completeError(e, s);
          } else {
            rethrow;
          }
        }
      } else {
        final v = from + (to - from) * (step / _fadeSteps);
        unawaited(_volume.setRampFactor(v));
      }
    });
    return done.future;
  }

  @override
  Future<void> loadQueue(List<SongModel> songs, {int initialIndex = 0, Duration? initialPosition}) async {
    final items = <MediaItem>[
      for (final s in songs) MediaItem(id: s.uri, title: s.title, artist: s.artist, album: s.album, duration: s.duration)
    ];
    final sources = <AudioSource>[
      for (final s in songs) AudioSource.uri(Uri.parse(s.uri))
    ];
    await _handler.loadTracks(items: items, sources: sources, initialIndex: initialIndex, initialPosition: initialPosition);
  }

  @override
  Future<void> insertSong(int index, SongModel song) async {
    final item = MediaItem(id: song.uri, title: song.title, artist: song.artist, album: song.album, duration: song.duration);
    final source = AudioSource.uri(Uri.parse(song.uri));
    await _handler.insertTrack(index, item, source);
  }

  @override
  Future<void> removeSong(int index) => _handler.removeTrack(index);
  @override
  Future<void> moveSong(int from, int to) => _handler.moveTrack(from, to);

  @override
  Future<void> play() async {
    _cancelRamp();
    final wasPlaying = _assumedPlaying;
    _assumedPlaying = true;
    await _handler.play();
    if (_fadeDuration <= Duration.zero || wasPlaying) return;
    // Duraklatılmıştan başlama: rampa çarpanı sıfırdan 1.0'a girer;
    // motora yazılan efektif ses = kullanıcı sesi × çarpan (duck/sönüm
    // katmanları aynen çarpılır).
    unawaited(_rampVolume(0.0, 1.0, null));
  }

  @override
  Future<void> pause() async {
    _cancelRamp();
    final wasPlaying = _assumedPlaying;
    _assumedPlaying = false;
    if (_fadeDuration <= Duration.zero || !wasPlaying) {
      await _handler.pause();
      return;
    }
    // FAZ 2: Future rampa BİTİNCE (ve fade-out sonundaki pause yapıldıktan
    // sonra) döner; play() bu arada gelirse jenerasyon eşleşmez, beklemedeki
    // pause atlanır ve Future yine tamamlanır.
    final from = _volume.rampFactor;
    await _rampVolume(from, 0.0, () => _handler.pause());
  }

  @override
  Future<void> stop() async {
    _cancelRamp();
    _assumedPlaying = false;
    // Rampayı temizle: ortada kalmış çarpan sonraki duck/sönüm yazımına
    // sızmasın (FAZ 2 katman hijyeni).
    unawaited(_volume.endRamp());
    await _handler.stop();
  }

  @override
  Future<void> seek(Duration position) => _handler.seek(position);
  @override
  Future<void> skipToNext() => _handler.skipToNext();
  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  @override
  Future<void> skipToIndex(int index) => _handler.skipToIndex(index);
  @override
  Future<void> setShuffleMode(bool enabled) => _handler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) => _handler.setRepeatMode(mode);

  @override
  Future<void> setVolume(double volume) async {
    // Kullanıcının ses tercihi rampadan önce gelir: fade varsa iptal
    // edilir ve kullanıcı rampayı devralır (eski sözleşme; tek yazımla
    // uygulanır).
    _cancelRamp();
    await _volume.userTakesOver(volume);
  }

  @override
  void setSleepDamping(double factor) {
    // FAZ 2: uyku sönümü bir katmandır — rampayı İPTAL ETMEZ, kullanıcı
    // sesini EZMEZ; koordinatör çarpımı tek yazımla bildirir. (Eski
    // davranış setVolume'e yazardı: aktif pause rampasını iptal eder,
    // gecikmeli pause hiç çalışmaz ve kullanıcının tercihi ezilirdi —
    // K2 yarışının kökü.)
    unawaited(_volume.setSleepDamping(factor));
  }

  @override
  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);
  @override
  Future<void> setPitch(double pitch) => _handler.setPitch(pitch);
  @override
  Future<void> setSkipSilenceEnabled(bool enabled) => _handler.setSkipSilenceEnabled(enabled);
  @override
  bool get hasNext => _handler.hasNext;
  @override
  bool get hasPrevious => _handler.hasPrevious;
}