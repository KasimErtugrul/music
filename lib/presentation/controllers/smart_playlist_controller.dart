import 'package:get/get.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class SmartPlaylistController extends GetxController {
  SmartPlaylistController(this._repo);
  final StatsRepository _repo;

  final songs = <SongModel>[].obs;
  final isLoading = true.obs;

  /// Bulgu 15: LibraryController'daki hasError sözleşmesi. Akıllı liste
  /// sayfası load'u initState'ten beklenmeden çağırır; DB hatası eskiden
  /// işlenmemiş async hata olurken artık hasError'a yazılır.
  final hasError = false.obs;

  Future<void> load(String key) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      songs.assignAll(await _repo.getSmartPlaylist(key));
    } on Object catch (e, st) {
      AppLog.error(e, st, source: 'SmartPlaylistController.load');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}