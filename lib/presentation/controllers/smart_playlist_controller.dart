import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class SmartPlaylistController extends GetxController {
  SmartPlaylistController(this._repo);
  final StatsRepository _repo;

  final songs = <SongModel>[].obs;
  final isLoading = true.obs;

  Future<void> load(String key) async {
    isLoading.value = true;
    try {
      songs.assignAll(await _repo.getSmartPlaylist(key));
    } finally {
      isLoading.value = false;
    }
  }
}