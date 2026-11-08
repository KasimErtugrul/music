import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/audio_format_datasource.dart';
import 'package:resonance/data/datasources/auto_browse_delegate.dart';
import 'package:resonance/data/datasources/metadata_datasource.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/audio_format_info.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/queue_state_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/vault_controller.dart';

class PlayerController extends GetxController implements AutoPlayController {
  PlayerController(
    this._repository,
    this._libraryRepo,
    this._stateRepo,
    this._historyRepo, {
    this.vault,
  });

  final PlayerRepository _repository;
  final LibraryRepository _libraryRepo;
  final QueueStateRepository _stateRepo;
  final HistoryRepository _historyRepo;

  /// Gün 17 (Kasa): son savunma hattı. Kasadaki şarkı kütüphaneden
  /// zaten süzüldüğü için bu koruma normalde hiç tetiklenmez; kuyruk
  /// geri yükleme ve harici açma gibi UI dışı yollara karşı durur.
  /// Bulgu 4: ayrıca [VaultController.entries] canlı dinlenir — küme
  /// değişince ÇALAN kuyruk da arınır (doğal geçiş/next() yollarının
  /// tek koruması budur). Null ise (bazı testler) koruma devre dışıdır.
  final VaultController? vault;
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

  Stream<PlaybackState> get playbackStateStream =>
      _repository.playbackStateStream;

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

  // Aşama 4: mini player kaydırma hareketleri. Kart aşağı kaydırıldığında
  // ince bir tutamağa küçülür (ekran alanı kazanımı); tutamağa dokunmak
  // veya yukarı kaydırmak kartı geri getirir. Kalıcı tercih DEĞİLDİR:
  // her uygulama açılışında kart görünür başlar.
  final miniPlayerHidden = false.obs;

  // Bulgu 4: kasa kümesi değişince canlı kuyruğun reaktif temizliği.
  // _vaultWorker: entries aboneliği (onClose'ta salınır). _purgingVault/
  // _purgeVaultQueued: üst üste kasa olaylarında tek koşu + kuyrukta
  // birleştirme; paralel koşular motor↔songQueue indeks kaydırması
  // yaratabilirdi.
  Worker? _vaultWorker;
  bool _purgingVault = false;
  bool _purgeVaultQueued = false;

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
    _bindPreferenceWatchers();
    _bindVaultWatcher();
    // Bulgu 4: restore bittiği anda bir temizlik geçişi — kuyruk geri
    // yükleme, kütüphane filtre indeksi bayatsa yasaklı kayıt taşıyabilir;
    // tek geçişle değişmez («canlı kuyrukta yasaklı yok») güvenceye alınır.
    unawaited(_restoreQueue().then<void>((_) => _purgeBannedFromQueue()));
  }

  @override
  void onClose() {
    _vaultWorker?.dispose();
    super.onClose();
  }

  DateTime? _lastPositionSave;

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

      // Bulgu 1: karıştırma/tekrar İKİ YÖNLÜ senkron. Bu denetleyici tek
      // mod sahibi değil: medya oturumu da handler.setShuffleMode /
      // setRepeatMode'u çağırabilir (bildirim kartı, Bluetooth/AVRCP,
      // sesli asistan «karıştır'ı aç», Android Auto). Handler, just_audio
      // dinleyicileriyle yeni PlaybackState yayınlar (audio_handler
      // _transformEvent: repeatMode + shuffleMode alanları dolu); bu
      // dinleyici o alanları okumazsa mini oynatıcı/oynatıcı sayfası
      // rozetleri bayat kalır ve _saveQueueState yanlış modu diske yazıp
      // yeniden başlatmada yanlış modu geri yükler. Yayın tek yönlüdür —
      // bu dinleyici depoya geri yazma yapmaz — döngü riski yoktur.
      // İlk değer: toggleShuffle/cycleRepeatMode iyimser Rx yazımı
      // yapar; buradan gelen yayın aynı değere yakınsar (idempotent).
      final streamShuffle = state.shuffleMode == AudioServiceShuffleMode.all;
      if (shuffleEnabled.value != streamShuffle) {
        shuffleEnabled.value = streamShuffle;
      }
      if (repeatMode.value != state.repeatMode) {
        repeatMode.value = state.repeatMode;
      }

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
      // İşlem ölümünde konum kaybolmasın: çalarken ~5 sn'de bir kaydet.
      if (!_isRestoring && isPlaying.value) {
        final now = DateTime.now();
        final last = _lastPositionSave;
        if (last == null ||
            now.difference(last) >= const Duration(seconds: 5)) {
          _lastPositionSave = now;
          unawaited(_saveQueueState());
        }
      }
    });

    _repository.durationStream.listen((dur) {
      // Bulgu 5: null bir BİLGİDİR — «süre bilinmiyor». just_audio
      // durationStream'i playbackEvent.duration'ı yayınlar; parça geçişi,
      // stop/idle ve yüklenemezken null düşer. Eskiden null yok
      // sayılıyordu ve bir önceki parçanın süresi aynen kalıyordu:
      // geçiş penceresinde seek bar oranı, «-kalan» etiketi, mini kart
      // ilerlemesi BAYAT toplamla hesaplanıyor, «parça sonu» uyku
      // zamanlayıcısı (sleep_timer_controller) kısa parçadan uzuna
      // geçişte YENİ parçanın ortasında yanlış tetikleniyordu.
      // null → Duration.zero dürüst «bilinmiyor» durumudur; tüm UI
      // tüketicileri totalMs>0 guard'lıdır (seek_bar, home_tab_content,
      // waveform_viewer, notification_settings, sleep_timer).
      duration.value = dur ?? Duration.zero;
    });
  }

  /// Gün 2: oynatmayla doğrudan ilgili tercihlerin canlı uygulaması.
  ///
  /// Karar (Gün 2): defaultShuffle/defaultRepeat canlı dinlenmez; yalnız
  /// yeni kuyruk başlarken (playSong) uygulanır. skipSilence ve replayGain
  /// ise alan-dinleyiciyle canlı uygulanır: ilgili alan DEĞİŞMEDİKÇE depoya
  /// dokunulmaz; modelin başka bir alanına yazılan tercihler boşuna platform
  /// çağrısı tetiklemez.
  ///
  /// Geri yükleme akışı (_restoreQueue) kendi tercihlerini açıkça uyguladığı
  /// için _isRestoring süresince dinleyici yalnız anlık görüntüyü günceller;
  /// çift uygulama ve açılışta yanlış tetiklenme engellenir. Yedek içe
  /// aktarma sonrası reload() (Gün 1) ise _isRestoring=false iken çalıştığı
  /// için içe aktarılan tercihler canlı oynatıcıya yansır (istenen davranış).
  void _bindPreferenceWatchers() {
    var prev = prefCtrl.playback.value;
    ever<PlaybackSettingsModel>(prefCtrl.playback, (cur) {
      if (_isRestoring) {
        prev = cur;
        return;
      }
      if (cur.skipSilence != prev.skipSilence) {
        unawaited(_applySkipSilenceLive(cur.skipSilence));
      }
      if (cur.replayGain != prev.replayGain && currentSong != null) {
        // _applyReplayGain hem açık hem kapalı yolunu bilir: tercih kapalıyken
        // kanal manuel loudness'e döner (Görev 2.3 sözleşmesi).
        unawaited(_applyReplayGain(currentSong!));
      }
      if (cur.fadeMs != prev.fadeMs) {
        // Gün 20: yumuşatma süresi canlı uygulanır; sonraki play/pause'ta
        // geçerlidir. Süreyi değiştirmek çalan sesi bozmaz.
        _repository.setFadeDuration(Duration(milliseconds: cur.fadeMs));
      }
      prev = cur;
    });
  }

  /// Gün 2: skipSilence tercihini çalan oynatıcıya anında uygular.
  /// Oynatıcı henüz hazır değilse hata yutulur; tercih kalıcıdır ve bir
  /// sonraki kuyrukta (playSong / oturum geri yükleme) yine uygulanır.
  Future<void> _applySkipSilenceLive(bool enabled) async {
    try {
      await _repository.setSkipSilenceEnabled(enabled);
    } on Object {
      // Ses akışını asla bozma.
    }
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

    // Bulgu 5: süresi bilinmeyen kayıt (durationMs<=0 → eşik 0) İLK
    // pozisyon olayında (pos>=0 her daim doğru) «dinlendi» sayılıyordu;
    // hiç dinlenmeyen şarkı en çok çalananlara, rozetlere ve istatistik
    // özetlerine işleniyordu. Eşik kurulamıyorsa kanıt yoktur: kayıt
    // yazılmaz (temkinli ve dürüst davranış).
    if (threshold <= Duration.zero) return;

    if (pos >= threshold) {
      unawaited(
        _historyRepo
            .recordPlay(song)
            .then<void>(
              (_) {},
              onError: (Object e, StackTrace st) =>
                  AppLog.error(e, st, source: 'recordPlay'),
            ),
      );
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
          // Gün 20: yumuşatma süresi (ses rampası depo katmanında yaşar).
          _repository.setFadeDuration(Duration(milliseconds: pref.fadeMs));
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

      // Kayıtlı state yoksa veya boşsa Varsayılanları uygula.
      // Gün 2: Rx durumu da senkronize edilir; aksi halde mini oynatıcının
      // shuffle/tekrar rozetleri depo durumundan geri kalırdı.
      final pref = prefCtrl.playback.value;
      await _repository.setShuffleMode(pref.defaultShuffle);
      shuffleEnabled.value = pref.defaultShuffle;
      repeatMode.value = _mapRepeatMode(pref.defaultRepeat);
      await _repository.setRepeatMode(_mapRepeatMode(pref.defaultRepeat));
    } catch (_) {
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _saveQueueState() async {
    if (songQueue.isEmpty) {
      try {
        await _stateRepo.clearState();
      } on Object catch (e, st) {
        AppLog.error(e, st, source: 'clearState');
      }
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
    } on Object catch (e, st) {
      AppLog.error(e, st, source: 'saveQueueState');
    }
  }

  AudioServiceRepeatMode _mapRepeatMode(int val) => switch (val) {
    1 => AudioServiceRepeatMode.all,
    2 => AudioServiceRepeatMode.one,
    _ => AudioServiceRepeatMode.none,
  };

  /// Gün 17 (Kasa): playSong'in dönüş değeri — kasadaki şarkı reddedilirse
  /// false döner ve hiçbir depo çağrısı yapılmaz (ses/QUEUE dokunulmaz).
  /// AutoPlayController sözleşmesi `Future<void>` bildirir; `Future<bool>`
  /// onun bir alt tipidir (arayanlar sonucu yok sayabilir).
  @override
  Future<bool> playSong(SongModel song, {List<SongModel>? queue}) async {
    // Gün 17: kasa koruması — şarkı yasaklıysa asla çalmaz.
    final vaultCtrl = vault;
    if (vaultCtrl != null && vaultCtrl.isBanned(song)) {
      _notifyVaultBlocked();
      return false;
    }

    // Varsayılanları uygula
    final pref = prefCtrl.playback.value;
    await _repository.setSpeed(pref.speed);
    await _repository.setPitch(pref.pitch);
    await _repository.setSkipSilenceEnabled(pref.skipSilence);
    // Gün 20: yumuşatma süresi (ses rampası depo katmanında yaşar).
    _repository.setFadeDuration(Duration(milliseconds: pref.fadeMs));
    // Gün 2 / Karar: varsayılan rastgele/tekrar yalnız YENİ KUYRUK
    // başlarken uygulanır (playSong = yeni kuyruk; playNext/addToQueue
    // yeniden uygulamaz). Kullanıcının mevcut kuyruk üzerindeki manuel
    // toggle'ları canlıyken asla geriye dönük ezilmez; yeni kuyruk
    // varsayılanla başlar. Rx değerleri depo çağrısıyla birlikte
    // senkronize edilir; aksi halde mini oynatıcı rozetleri eski durumu
    // gösterirdi.
    shuffleEnabled.value = pref.defaultShuffle;
    await _repository.setShuffleMode(pref.defaultShuffle);
    final repeat = _mapRepeatMode(pref.defaultRepeat);
    repeatMode.value = repeat;
    await _repository.setRepeatMode(repeat);

    // Görev 2.3: parça başına ReplayGain (etiket yoksa kazanç 0 dB).
    await _applyReplayGain(song);

    final list = queue ?? <SongModel>[song];
    // Bulgu 4: yeni kuyruğun TAMAMI kasa filtresinden geçer. Eski kod
    // yalnız hedef şarkıyı kontrol ediyordu; liste kaynağı bayatsa
    // (çalma listesi satırı, eski anlık görüntü) yasaklı kayıt kuyruğa
    // sızaibılır ve doğal geçişte çalabilirdi. Liste kaynakları filtreli
    // kütüphaneden gelse de bu satır «son savunma hattı» sözleşmesini
    // (yukarıdaki alan belgesi) kuyruk için de taşır.
    var safeList = list;
    if (vaultCtrl != null && list.any(vaultCtrl.isBanned)) {
      safeList = list.where((s) => !vaultCtrl.isBanned(s)).toList();
      if (safeList.isEmpty) safeList = <SongModel>[song];
    }
    final index = safeList.indexWhere((s) => s.id == song.id);

    final previousQueue = List<SongModel>.of(songQueue);
    songQueue.assignAll(safeList);
    try {
      await _repository.loadQueue(
        safeList,
        initialIndex: index < 0 ? 0 : index,
      );
      await _repository.play();
    } on Object catch (e, st) {
      // Kaynak yüklenemediyse arayüz kuyruğu gerçek oynatma listesinden
      // ayrışmasın: önceki kuyruk geri yüklenir.
      songQueue.assignAll(previousQueue);
      AppLog.error(e, st, source: 'playSong');
      rethrow;
    }
    return true;
  }

  /// Gün 17: kasadan çalma denemesi bildirimi. Denetleyici katmanından
  /// arayüze tek köprü Get.context üzerinden l10n'dir (LibraryController
  /// deseninin aynısı); bağlam yoksa sessizce döner.
  void _notifyVaultBlocked() {
    final context = Get.context;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    Get.snackbar(
      l10n.vaultTitle,
      l10n.bannedToast,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Bulgu 4: kasa kümesi değişimini CANLI kuyruğa yansıtan reaktif köprü.
  ///
  /// Sözleşme kırılması şuydu: ban/unban kütüphaneyi ve kasa listesini
  /// canlı güncellerken çalan kuyruk «anlık kopya» olarak bayat kalmıştı
  /// (song_options_sheet'teki yorumun kendisi bunu belgeler). Kuyrukta
  /// duran yasaklı şarkı, parça bitiminde just_audio içindeki doğal
  /// geçişle veya next() ile ÇALIYORDU — «asla çalamaz» sözleşmesi
  /// (settingsDescVault) yalnız giriş noktalarında (playSong/playNext/
  /// addToQueue/playFromQueue) uygulanıyordu, geçiş yollarında değil.
  ///
  /// Tek zorlama noktası bu yüzden kuyruğun kendisidir: küme değişir →
  /// canlı kuyruk arınır. Böylece doğal geçiş, manuel skip, öncekiye
  /// dönme gibi TÜM geçiş yolları tek değişmezle korunur: «canlı
  /// kuyrukta yasaklı kayıt bulunamaz.»
  void _bindVaultWatcher() {
    final vaultCtrl = vault;
    if (vaultCtrl == null) return;
    _vaultWorker = ever<List<BannedSongModel>>(vaultCtrl.entries, (_) {
      unawaited(_purgeBannedFromQueue());
    });
  }

  /// Bulgu 4: temizlik koşularını serileştirir. Aynı turda birden çok
  /// kasa olayı gelirse (ban + akış bildirimi) koşular birleştirilir;
  /// paralel koşu aynı indeks üzerinde iki silme yapabilirdi.
  Future<void> _purgeBannedFromQueue() async {
    final vaultCtrl = vault;
    if (vaultCtrl == null || _isRestoring) return;
    if (_purgingVault) {
      _purgeVaultQueued = true;
      return;
    }
    _purgingVault = true;
    try {
      do {
        _purgeVaultQueued = false;
        await _purgeBannedOnce();
      } while (_purgeVaultQueued);
    } finally {
      _purgingVault = false;
    }
  }

  /// Bulgu 4: tek temizlik geçişi. songQueue ve motor çalma listesi
  /// aynı silme dizisini uygular; her adımda ikisi kilitli kalır.
  Future<void> _purgeBannedOnce() async {
    final vaultCtrl = vault;
    if (vaultCtrl == null) return;

    final curIdx = _repository.currentIndex ?? -1;
    final toRemove = <int>[];
    for (var i = 0; i < songQueue.length; i++) {
      if (i != curIdx && vaultCtrl.isBanned(songQueue[i])) toRemove.add(i);
    }
    // Büyük indisten küçüğe sil: küçükten silinse sonraki indeksler
    // kayar, yanlış kayıt düşerdi.
    for (final i in toRemove.reversed) {
      if (i >= songQueue.length) continue;
      final removed = songQueue.removeAt(i);
      try {
        await _repository.removeSong(i);
      } on Object catch (e, st) {
        // Motor düşmediyse UI geri sarar; kuyruk↔motor listesi
        // AYRIŞMAZ (bu denetimin temel değişmezi).
        songQueue.insert(i, removed);
        AppLog.error(e, st, source: 'purgeBannedFromQueue');
        return;
      }
    }

    // Çalan parçanın GÜNCEL indisi: altındaki kayıtlar silindiyse
    // motorun indisi kaymıştır; kimliği değil motorun söylediğini oku.
    final curNow = _repository.currentIndex ?? -1;
    if (curNow < 0 || curNow >= songQueue.length) return;
    if (!vaultCtrl.isBanned(songQueue[curNow])) return;

    // Çalan parça kasada: kaynağı düşür. Motor, aynı indisteki bir
    // sonraki kayda kendi kendine geçer (removeFromQueue'nun bugüne
    // kullandığı ilkelin aynısı); oynatma durumu motorun elinde kalır —
    // duraklatılmış oturumda sessizlik bozulmaz. Tek kayıt kaldıysa
    // kuyruk biter: tam duruş (clearQueue/removeFromQueue sözleşmesi).
    final removed = songQueue.removeAt(curNow);
    try {
      await _repository.removeSong(curNow);
    } on Object catch (e, st) {
      songQueue.insert(curNow, removed);
      AppLog.error(e, st, source: 'purgeBannedFromQueue');
      return;
    }
    if (songQueue.isEmpty) {
      try {
        await _repository.stop();
      } on Object catch (e, st) {
        AppLog.error(e, st, source: 'purgeBannedFromQueue');
      }
    }
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

  /// Gün 15: hızlı hız seçeneklerinin TEK kaynağı. SpeedPitchSheet'in
  /// çipleriyle harici oynatıcının hız döngüsü aynı listeyi kullanırdı;
  /// iki kopya sabit tekilleştirildi.
  static const List<double> quickSpeeds = <double>[0.8, 1.0, 1.25, 1.5];

  /// Gün 15: kalıcılık tek doğruluk kaynağına taşındı. Eskiden
  /// SpeedPitchSheet iki çağrı yapıyordu (PreferencesController.setSpeed +
  /// buraya canlı çağrı), harici oynatıcının hız döngüsü ise YALNIZ canlı
  /// çağrı yapıyordu — kalıcı tercihe yazmıyordu ve iki kontrol tercih
  /// dosyasıyla ayrışıyordu (sheet'in gösterdiği değer ile sonraki
  /// playSong/oturum geri yüklemesinin uyguladığı değer farklılaşıyordu).
  /// Artık canlı uygulamanın yanında kalıcı tercih de buradan yazılır;
  /// çağıranlar tek metodu çağırır. Tercih değişimi _bindPreferenceWatchers
  /// içindeki alan dinleyicisini tetiklese bile hız alanı orada
  /// dinlenmediğinden ek bir depo çağrısı oluşmaz (döngü yok).
  Future<void> setSpeed(double speed) async {
    await _repository.setSpeed(speed);
    prefCtrl.setSpeed(speed);
  }

  /// Gün 15: [setSpeed] ile aynı sözleşme — canlı uygulama + kalıcı tercih
  /// tek çağrıda. (Harici oynatıcı perdeyi değiştirmese de sözleşme
  /// simetriktir; SpeedPitchSheet artık ikisini de tek çağrıyla yapar.)
  Future<void> setPitch(double pitch) async {
    await _repository.setPitch(pitch);
    prefCtrl.setPitch(pitch);
  }

  Future<void> playNext(SongModel song) async {
    // Gün 17: kasadaki şarkı kuyruğa da eklenemez.
    final vaultCtrl = vault;
    if (vaultCtrl != null && vaultCtrl.isBanned(song)) {
      _notifyVaultBlocked();
      return;
    }
    if (songQueue.isEmpty) {
      await playSong(song);
      return;
    }
    final nextIdx = (_repository.currentIndex ?? 0) + 1;
    songQueue.insert(nextIdx, song);
    await _repository.insertSong(nextIdx, song);
  }

  Future<void> addToQueue(SongModel song) async {
    // Gün 17: kasadaki şarkı kuyruğa da eklenemez.
    final vaultCtrl = vault;
    if (vaultCtrl != null && vaultCtrl.isBanned(song)) {
      _notifyVaultBlocked();
      return;
    }
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

  /// [newIndex] «çıkarma sonrası» konumdur (onReorderItem önceden düzeltir);
  /// moveTrack→moveAudioSource zinciri de bu sözleşmede, -1 tekrarlanmaz.
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final song = songQueue.removeAt(oldIndex);
    songQueue.insert(newIndex, song);
    await _repository.moveSong(oldIndex, newIndex);
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
  }

  Future<void> seek(Duration pos) => _repository.seek(pos);
  Future<void> next() => _repository.skipToNext();
  Future<void> previous() => _repository.skipToPrevious();

  /// Bulgu 3: kuyruğun gerçek «şu an çalan» indisi. songQueue orijinal
  /// sırayı tuttuğu için bu indisteki kayıt currentSong ile birebir aynıdır.
  /// UI (kuyruk sayfası) uri eşleşmesi yerine bunu okur; aynı şarkı
  /// kuyrukta iki kez varken yanlış kaydın vurgulanmasını engeller.
  int? get currentQueueIndex => _repository.currentIndex;

  /// Bulgu 3: kuyruk sayfasındaki bir kayda doğrudan atlama.
  ///
  /// Eskiden kuyruktan şarkı seçmek playSong(song, queue: fullQueue)
  /// çağırıyordu; playSong «yeni kuyruk» sözleşmesi gereği karıştırma/
  /// tekrar modunu TERCİHTEKİ VARSAYILANA geri çekiyor ve setAudioSources
  /// ile tüm kuyruğu yeniden kuruyordu. Artık kuyruk hiç yeniden kurulmaz
  /// (skipToIndex: just_audio seek(index)), kullanıcı o an seçili karıştırma/
  /// tekrar modu aynen korunur ve kasadaki şarkı koruması aynen geçerlidir.
  /// Dönüş değeri: atlama yapıldıysa true.
  Future<bool> playFromQueue(int index) async {
    if (index < 0 || index >= songQueue.length) return false;
    final song = songQueue[index];
    final vaultCtrl = vault;
    if (vaultCtrl != null && vaultCtrl.isBanned(song)) {
      _notifyVaultBlocked();
      return false;
    }
    try {
      await _applyReplayGain(song);
      await _repository.skipToIndex(index);
      await _repository.play();
    } on Object catch (e, st) {
      AppLog.error(e, st, source: 'playFromQueue');
      rethrow;
    }
    return true;
  }

  /// Aşama 4: mini player kartını ince tutamağa küçültür
  /// (kartta aşağı kaydırma hareketi).
  void hideMiniPlayer() => miniPlayerHidden.value = true;

  /// Aşama 4: küçültülen kartı geri açar
  /// (tutamağa dokunma veya yukarı kaydırma hareketi).
  void showMiniPlayer() => miniPlayerHidden.value = false;

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
      final lossless = const {
        'flac',
        'wav',
        'aiff',
        'ape',
        'alac',
      }.contains(codec.toLowerCase());
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
