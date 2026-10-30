import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
// Gün 11: resetAll'ın canlı tazeleme zinciri tek doğruluk kaynağından gelir
// (Gün 7). Not: live_settings_reload.dart zincirde PreferencesController'ı
// kullandığı için bu import bir döngü kurar; Dart'ta kütüphane import
// döngüsü yasaldır ve iki taraf da yalnız tanımlara başvurur (top-level
// başlatma döngüsü yok).
import 'package:resonance/presentation/controllers/live_settings_reload.dart';

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

  /// Gün 6: "Tüm ayarları sıfırla" akışı. Diskteki TÜM yedeklenen ayar
  /// anahtarları (SettingsPersistence.backupKeys) kaldırılır (repo'da),
  /// canlı Rx durumu fabrika değerine döner ve ayar taşıyan tüm canlı
  /// controller'lar yeniden yüklenir — kullanıcı uygulama yeniden
  /// başlatmadan varsayılanlara döner (Gün 1'deki BackupController
  /// kalıbının aynısı). Sıra önemlidir: EqualizerController.reload()
  /// içinden PreferencesController okunur; o yüzden önce kendi durumumuz
  /// tazelenir, sonra zincir çalışır.
  ///
  /// Gün 11: zincir Gün 7'nin tek doğruluk kaynağına bağlandı
  /// (live_settings_reload.dart). Gün 6'dan kalma özel _reloadLiveControllers
  /// kopyası silindi — «çağrı noktaları listeyi kopyalamasın» ilkesi artık
  /// üç çağrı noktasında da geçerli: manuel içe aktarma (Gün 1), otomatik
  /// geri yükleme (Gün 7), tümünü sıfırla (bugün). Paylaşılan zincir
  /// PreferencesController'ı (kendi örneğimizi) da yeniden yükler: disk
  /// temizlendikten SONRA çalıştığı için yeniden okuma aynı fabrika
  /// değerlerini verir (idempotent); yukarıdaki inline atama yalnız
  /// senkron ilk görünümdür. Zincirin hata sözleşmesi Gün 1'le aynıdır:
  /// kayıtsız controller sessizce atlanır, tek bir reload hatası
  /// sıfırlamayı başarısız saymaz.
  Future<void> resetAll() async {
    await _repo.resetAll();
    playback.value = const PlaybackSettingsModel();
    library.value = const LibrarySettingsModel();
    await reloadLiveSettingsControllers();
  }

}