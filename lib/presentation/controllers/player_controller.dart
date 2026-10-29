import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/audio_format_datasource.dart';
import 'package:resonance/data/datasources/metadata_datasource.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/audio_format_info.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/queue_state_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
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

  // Görev 2.3: ReplayGain kazancı en son hangi parçaya uygulandı? playSong,
  // oturum geri yükleme ve doğal (otomatik) parça geçişleri aynı yardımcıyı
  // kullanır; bu işaretçi çift etiket okumasını ve çift kazanç yazmasını
  // engeller.
  String? _replayGainAppliedUri;

  // Aşama 2: format rozeti. Şarkı başına bir kez başlık okunur, sonuç
  // önbelleğe alınır; kuyruk içi geçişlerde cache isabeti kullanılır.
  // Bilgi okunamazsa null kalır ve rozet gizlenir.
  final formatInfo = Rxn<AudioFormatInfo>();
  final Map<int, AudioFormatInfo?> _formatCache = <int, AudioFormatInfo?>{};



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
        // Şarkı değişti: eski rozet anında gizlenir, yenisi arka planda
        // okunur (önbellek isabetiyle anında gelir).
        formatInfo.value = null;
        unawaited(_updateFormatInfo());
      }
      currentItem.value = item;

      // Görev 2.3: kuyruk kendi ilerleyince (otomatik geçiş) playSong
      // çağrılmaz; kazancın parça başına güncellenmesi için doğal geçişler
      // burada yakalanır. playSong ve geri yükleme akışı uri'yi önceden
      // işaretlediği için bu dinleyici o durumda tekrar okumaz.
      // Not: MediaItem.id, PlayerRepositoryImpl tarafından song.uri'ye
      // eşittir; eşleşme index zamanlamasına değil uri'ye bakar.
      if (!_isRestoring && item != null && item.id != _replayGainAppliedUri) {
        SongModel? naturalSong;
        for (final s in songQueue) {
          if (s.uri == item.id) {
            naturalSong = s;
            break;
          }
        }
        if (naturalSong != null) _applyReplayGain(naturalSong);
      }

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

          // Görev 2.1: oturum geri yüklemede ses tercihlerini uygula.
          // Eski akış kuyruğu hız/pitch/sessizlik-atla tercihleri olmadan
          // yüklüyordu; otomatik-devam tercihi ise hiç okunmuyordu.
          // PreferencesController'ın Completer tabanlı ready yardımcısı
          // (Görev 1.5) tercihlerin diskten yüklendiğini garanti eder;
          // hata durumunda da tamamlanır, akış kilitlenmez.
          await prefCtrl.ready;
          final pref = prefCtrl.playback.value;
          await _repository.setSpeed(pref.speed);
          await _repository.setPitch(pref.pitch);
          await _repository.setSkipSilenceEnabled(pref.skipSilence);

          // Görev 2.3: geri yüklenen ilk parçaya ReplayGain uygula.
          await _applyReplayGain(restored[safeIndex]);

          await _repository.loadQueue(
            restored,
            initialIndex: safeIndex,
            initialPosition: state.position,
          );

          // Görev 2.1: tercih açıksa kaldığı yerden oynatmaya devam et.
          // loadQueue hataya düşerse play satırına ulaşılmaz; bozuk bir
          // geri yükleme asla beklenmedik oynatma başlatmaz.
          if (pref.autoResume) await _repository.play();
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

    // Görev 2.3: parça başına ReplayGain (etiket yoksa kazanç 0 dB).
    await _applyReplayGain(song);

    final list = queue ?? <SongModel>[song];
    final index = list.indexWhere((s) => s.id == song.id);

    songQueue.assignAll(list);
    await _repository.loadQueue(list, initialIndex: index < 0 ? 0 : index);
    await _repository.play();
  }

  /// Görev 2.3: ReplayGain uygulaması.
  ///
  /// - Tercih açık: parçanın REPLAYGAIN_TRACK_GAIN etiketi okunur ve hedef
  ///   kazanç olarak uygulanır (etiket yoksa 0 dB). LoudnessEnhancer kanalı
  ///   bu akışta etkinleştirilir; ekolayzer anahtarının açık olmasına gerek
  ///   yoktur (Görev 2.3 kanal ayrımı).
  /// - Tercih kapalı: kanal kontrolü ekolayzer tarafına döner; kalıcı manuel
  ///   loudness değeri (Görev 2.4 anahtarı) geri yüklenir. Böylece önceki
  ///   parçadan kalan ReplayGain kazancı sonraki parçalara sızmaz.
  /// - Otomatik parça geçişi: mediaItem dinleyicisi işaretçi sayesinde
  ///   yalnızca doğal geçişlerde bu yardımcıyı çağırır; kullanıcı
  ///   başlatmalı çalmalarda playSong zaten uygulamıştır.
  ///
  /// Birim: her iki kanal da dB cinsindendir. just_audio'nun Dart API'si dB
  /// bekler; Android'e geçişte Java katmanı değeri x100 ile milibele çevirir.
  ///
  /// Bilinen sınırlama (yol haritası): manuel loudness ile ReplayGain
  /// kazancı toplanmaz (kaskad); tercih açıkken parça kazancı son sözü
  /// söyler.
  Future<void> _applyReplayGain(SongModel song) async {
    _replayGainAppliedUri = song.uri; // hem başarı hem hata yolunda işaretle
    try {
      final effects = Get.find<AudioEffectsDatasource>();
      final pref = prefCtrl.playback.value;
      if (pref.replayGain) {
        final gainDb = await Get.find<MetadataDatasource>().replayGainDb(song);
        await effects.setLoudnessEnabled(true);
        await effects.setLoudnessGain(gainDb ?? 0.0);
      } else {
        final eqRepo = Get.find<EqualizerRepository>();
        final manualLoudness = eqRepo.loadLoudness() ?? 0.0;
        if (manualLoudness != 0.0 && await eqRepo.isEnabled()) {
          await effects.setLoudnessEnabled(true);
          await effects.setLoudnessGain(manualLoudness);
        } else {
          await effects.setLoudnessEnabled(false);
          await effects.setLoudnessGain(0.0);
        }
      }
    } catch (_) {
      // Kazanç uygulaması ses akışını asla bozmamalıdır.
    }
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

  /// Oynatıcı sayfasındaki sanatçı adına dokunulduğunda sanatçının tüm
  /// şarkılarını gösteren [ArtistDetailPage]'e yönlendirir.
  ///
  /// Eşleştirme sırası: şarkının `artistId`'si ile kütüphane sanatçı
  /// listesi → eşleşmezse ada (büyük/küçük harf duyarsız) → o da yoksa
  /// sanatçı etiketsiz şarkılar için "bilinmeyen sanatçı" kovası.
  /// Kütüphane denetleyicisi hazır değilse veya eşleşme bulunamazsa
  /// sessizce no-op olur (ör. dış dosya oynatıcısından gelmişse).
  void openArtistDetail() {
    final song = currentSong;
    if (song == null) return;
    if (!Get.isRegistered<LibraryController>()) return;
    final artists = Get.find<LibraryController>().artists;

    ArtistModel? match;
    final artistId = song.artistId;
    if (artistId != null) {
      for (final a in artists) {
        if (a.id == artistId) {
          match = a;
          break;
        }
      }
    }
    final name = song.artist?.trim();
    if (match == null && name != null && name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final a in artists) {
        final n = a.name?.trim().toLowerCase();
        if (n != null && n == lower) {
          match = a;
          break;
        }
      }
    }
    if (match == null && (name == null || name.isEmpty)) {
      for (final a in artists) {
        if (a.isUnknown) {
          match = a;
          break;
        }
      }
    }
    if (match == null) return;
    Get.toNamed<dynamic>(AppRoutes.artistDetail, arguments: match);
  }

  /// Oynatıcı sayfasındaki albüm adına dokunulduğunda albüm detay
  /// sayfasını açar. Eşleştirme, kütüphane deposundaki `_albumIdOf`
  /// mantığıyla tutarlıdır: albüm etiketi VE albumId birlikte varsa id
  /// eşleşmesi; eşleşmezse başlığa göre; o da yoksa "bilinmeyen albüm"
  /// kovası. Kütüphane hazır değilse no-op olur.
  void openAlbumDetail() {
    final song = currentSong;
    if (song == null) return;
    if (!Get.isRegistered<LibraryController>()) return;
    final albums = Get.find<LibraryController>().albums;

    AlbumModel? match;
    final albumId = song.albumId;
    if (song.album != null && albumId != null) {
      for (final a in albums) {
        if (a.id == albumId) {
          match = a;
          break;
        }
      }
    }
    final title = song.album?.trim();
    if (match == null && title != null && title.isNotEmpty) {
      final lower = title.toLowerCase();
      for (final a in albums) {
        final t = a.title?.trim().toLowerCase();
        if (t != null && t == lower) {
          match = a;
          break;
        }
      }
    }
    if (match == null && (title == null || title.isEmpty)) {
      for (final a in albums) {
        if (a.isUnknown) {
          match = a;
          break;
        }
      }
    }
    if (match == null) return;
    Get.toNamed<dynamic>(AppRoutes.albumDetail, arguments: match);
  }

  /// Şu an çalan şarkının format bilgisini okur (önbellekli).
  /// Oynatıcı sayfasındaki format rozetini besler; okuma başarısızsa
  /// rozet gizlenir, asla çalmayı etkilemez.
  Future<void> _updateFormatInfo() async {
    final song = currentSong;
    if (song == null) {
      formatInfo.value = null;
      return;
    }
    if (_formatCache.containsKey(song.id)) {
      formatInfo.value = _formatCache[song.id];
      return;
    }
    AudioFormatInfo? info;
    try {
      info = await Get.find<AudioFormatDatasource>().read(song.path);
    } on Object {
      info = null; // Datasource kayıtlı değil veya okuma patladı → rozet yok.
    }
    info = _fallbackEnrich(song, info);
    _formatCache[song.id] = info;
    // Okuma sürerken şarkı değişmişse eski şarkıya yazma.
    if (currentSong?.id == song.id) {
      formatInfo.value = info;
    }
  }

  /// Başlıktan okunan bilgiyi zenginleştirir:
  /// - Hiç bilgi yoksa uzantıdan codec tahmini (FLAC/MP3/AAC...)
  /// - Bit hızı yoksa boyut/süreOranı'ndan ortalama kbps
  AudioFormatInfo? _fallbackEnrich(SongModel song, AudioFormatInfo? info) {
    final avgKbps = song.durationMs > 0
        ? (song.sizeBytes * 8 / song.durationMs).round()
        : 0;
    if (info == null) {
      final codec = _codecFromExtension(
        song.path.isNotEmpty ? song.path : song.uri,
      );
      if (codec == null) return null;
      final lossless = const {'flac', 'wav', 'aiff', 'ape', 'alac'}
          .contains(codec.toLowerCase());
      return AudioFormatInfo(
        codec: codec,
        bitrateKbps: avgKbps > 0 ? avgKbps : null,
        lossless: lossless,
      );
    }
    if (info.bitrateKbps == null && avgKbps > 0) {
      return info.copyWith(bitrateKbps: avgKbps);
    }
    return info;
  }

  /// Uzantıdan kısa codec etiketi; tanınmayan uzantıda null.
  static String? _codecFromExtension(String pathOrUri) {
    final clean = pathOrUri.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot < 0 || dot == clean.length - 1) return null;
    switch (clean.substring(dot + 1).toLowerCase()) {
      case 'flac':
        return 'FLAC';
      case 'mp3':
        return 'MP3';
      case 'm4a':
      case 'mp4':
      case 'm4b':
      case 'aac':
        return 'AAC';
      case 'ogg':
      case 'oga':
        return 'OGG';
      case 'opus':
        return 'Opus';
      case 'wav':
        return 'WAV';
      case 'aiff':
      case 'aif':
        return 'AIFF';
      case 'wv':
        return 'WavPack';
      case 'ape':
        return 'APE';
      default:
        return null;
    }
  }
}
