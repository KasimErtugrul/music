import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';

class PreferencesController extends GetxController {
  PreferencesController(this._repo);
  final PreferencesRepository _repo;

  final playback = const PlaybackSettingsModel().obs;
  final library = const LibrarySettingsModel().obs;
  final isLoading = true.obs;

  /// Tercihlerin diskten yüklenme işleminin bittiğini bildiren hazır (ready)
  /// yardımcısı. Revize notu (kullanıcı incelemesi sonrası): koşullu açılış
  /// taraması, indeks kalıcılığı sağlanmadan doğru semantik veremez
  /// (_ensureIndex zaten ilk erişimde taze MediaStore sorgusu atıyor; kapalı
  /// senaryosu içinse indeksin kalıcılaştırılması gerekir). Bu yüzden bu
  /// yardımcının Aşama 1'deki tek tüketicisi yoktur; Aşama 2'deki oturum
  /// geri yükleme görevinin (2.1 autoResume) ön koşulu olarak tutulur.
  ///
  /// Yükleme hata verse bile completer tamamlanır; aksi halde bozuk bir
  /// SharedPreferences durumunda açılış akışı sonsuza dek kilitlenirdi.
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      playback.value = await _repo.loadPlayback();
      library.value = await _repo.loadLibrary();
    } on Object {
      // Yüklenemezse model varsayılanları geçerli kalır;
      // ready yine de tamamlanır (açılış akışı kilitlenmez).
    } finally {
      isLoading.value = false;
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Gün 1: yedek içe aktarma sonrası diskteki tercihleri yeniden okur.
  /// Uygulama yeniden başlatmadan canlı Rx durumu güncellenir; hata durumunda
  /// mevcut değerler korunur.
  Future<void> reload() async {
    try {
      playback.value = await _repo.loadPlayback();
      library.value = await _repo.loadLibrary();
    } on Object catch (e) {
      // Yüklenemezse mevcut canlı durum korunur.
      debugPrint('PreferencesController.reload hatası: $e');
    }
  }

  void setSeekInterval(int seconds) {
    playback.value = playback.value.copyWith(seekIntervalSeconds: seconds);
    _repo.savePlayback(playback.value);
  }

  void setAutoResume(bool v) {
    playback.value = playback.value.copyWith(autoResume: v);
    _repo.savePlayback(playback.value);
  }

    void setSpeed(double speed) {
    playback.value = playback.value.copyWith(speed: speed);
    _repo.savePlayback(playback.value);
  }

  void setPitch(double pitch) {
    playback.value = playback.value.copyWith(pitch: pitch);
    _repo.savePlayback(playback.value);
  }

  /// Gün 2: KULLANILMIYOR — hiçbir UI anahtarı bu yöntemi çağırmaz; model
  /// alanı yalnızca eski JSON/yedek uyumluluğu için yaşar. Yöntem, Gün 1
  /// yedek anahtar kapsamı testi (settings_backup_keys_test) yazmaya devam
  /// etsin ve JSON çıkışında alan kaybolmasın diye bilinçli olarak tutuldu.
  void setGapless(bool v) {
    playback.value = playback.value.copyWith(gapless: v);
    _repo.savePlayback(playback.value);
  }

  void setReplayGain(bool v) {
    playback.value = playback.value.copyWith(replayGain: v);
    _repo.savePlayback(playback.value);
  }

  void setSkipSilence(bool v) {
    playback.value = playback.value.copyWith(skipSilence: v);
    _repo.savePlayback(playback.value);
  }

  void setPauseOnHeadphone(bool v) {
    playback.value = playback.value.copyWith(pauseOnHeadphone: v);
    _repo.savePlayback(playback.value);
  }

  void setDefaultShuffle(bool v) {
    playback.value = playback.value.copyWith(defaultShuffle: v);
    _repo.savePlayback(playback.value);
  }

  void setDefaultRepeat(int v) {
    playback.value = playback.value.copyWith(defaultRepeat: v);
    _repo.savePlayback(playback.value);
  }

  void setScanOnStartup(bool v) {
    library.value = library.value.copyWith(scanOnStartup: v);
    _repo.saveLibrary(library.value);
  }

  void setMinDuration(int seconds) {
    library.value = library.value.copyWith(minDurationSeconds: seconds);
    _repo.saveLibrary(library.value);
  }

  Future<void> resetAll() async {
    await _repo.resetAll();
    playback.value = const PlaybackSettingsModel();
    library.value = const LibrarySettingsModel();
  }
}
