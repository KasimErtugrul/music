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

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    playback.value = await _repo.loadPlayback();
    library.value = await _repo.loadLibrary();
    isLoading.value = false;
  }

  void setSeekInterval(int seconds) {
    playback.value = playback.value.copyWith(seekIntervalSeconds: seconds);
    _repo.savePlayback(playback.value);
  }

  void setAutoResume(bool v) {
    playback.value = playback.value.copyWith(autoResume: v);
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