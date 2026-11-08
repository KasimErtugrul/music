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
  int? get currentIndex => _handler.currentIndex;

  // --- Gün 20: yumuşatma (fade) -------------------------------------------
  // Oynat/duraklat sesi [_fadeSteps] adımda hedefe taşır. Rampa, kullanıcının
  // kayıtlı hedef sesine ([_volumeTarget]) göre yapılır; kullanıcı fade
  // sırasında sesi değiştirirse (setVolume) rampa iptal edilir. Jenerasyon
  // sayacı, iptal edilmiş bir rampanın son tıkının (örn. fade-out'un
  // sonundaki pause) geç yazmasını engeller.
  static const int _fadeSteps = 20;

  Timer? _fadeTimer;
  int _fadeGeneration = 0;
  Duration _fadeDuration = Duration.zero;
  double _volumeTarget = 1.0;

  /// Rampa son bilinen değeri; fade-out bir önceki fade-in'in ortasında
  /// başlarsa kaldığı yerden inmek için kullanılır.
  double _fadeValue = 1.0;

  /// Son bilinen çalma durumu. Kulaklık çıkarmada duraklatma, ses akışı
  /// katmanında (AudioSessionDatasource) yapıldığı için depoyu geçmez;
  /// o yolda [_assumedPlaying] true kalır ve sonraki play() rampasız
  /// çalar — ses zaten hedefte olduğundan tutarlıdır.
  bool _assumedPlaying = false;

  @override
  void setFadeDuration(Duration duration) {
    _fadeDuration = duration;
  }

  void _cancelFade() {
    _fadeGeneration++;
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  /// [from] → [to] arasında [_fadeSteps] adımlı ses rampası. Başlangıçta
  /// [from] hemen yazılır (ilk adım aralığı eski sesle çalınmasın); bitişte
  /// tam [to] yazılır ve [then] çalışır (fade-out sonunda pause gibi).
  /// [then], rampa bu arada iptal edildiyse atlanır.
  void _rampVolume(double from, double to, Future<void> Function()? then) {
    final gen = _fadeGeneration;
    _fadeValue = from;
    unawaited(_handler.setVolume(from));
    final stepGap = Duration(
      microseconds: _fadeDuration.inMicroseconds ~/ _fadeSteps,
    );
    var step = 0;
    _fadeTimer = Timer.periodic(stepGap, (timer) {
      if (gen != _fadeGeneration) {
        timer.cancel();
        return;
      }
      step++;
      if (step >= _fadeSteps) {
        timer.cancel();
        _fadeTimer = null;
        _fadeValue = to;
        unawaited(() async {
          await _handler.setVolume(to);
          if (gen != _fadeGeneration) return; // bu arada iptal olduysa son eylemi atla
          await then?.call();
        }());
      } else {
        final v = from + (to - from) * (step / _fadeSteps);
        _fadeValue = v;
        unawaited(_handler.setVolume(v));
      }
    });
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
    _cancelFade();
    final wasPlaying = _assumedPlaying;
    _assumedPlaying = true;
    await _handler.play();
    if (_fadeDuration <= Duration.zero || wasPlaying) return;
    // Duraklatılmıştan başlama: ses sıfırdan hedefe girer.
    _rampVolume(0.0, _volumeTarget, null);
  }

  @override
  Future<void> pause() async {
    _cancelFade();
    final wasPlaying = _assumedPlaying;
    _assumedPlaying = false;
    if (_fadeDuration <= Duration.zero || !wasPlaying) {
      await _handler.pause();
      return;
    }
    // Ses hedefe inince duraklat; play() bu arada gelirse jenerasyon
    // eşleşmez ve beklemedeki pause atlanır.
    final from = _fadeValue.clamp(0.0, 1.0).toDouble();
    _rampVolume(from, 0.0, () => _handler.pause());
  }

  @override
  Future<void> stop() async {
    _cancelFade();
    _assumedPlaying = false;
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
    // Kullanıcının ses tercihi rampadan önce gelir: fade varsa iptal edilir.
    _volumeTarget = volume;
    if (_fadeTimer != null) _cancelFade();
    _fadeValue = volume;
    await _handler.setVolume(volume);
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