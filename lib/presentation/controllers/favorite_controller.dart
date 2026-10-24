import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';

class FavoriteController extends GetxController {
  FavoriteController(this._repo);
  final FavoriteRepository _repo;

  final favoriteIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _repo.watchFavoriteIds().listen((ids) => favoriteIds.assignAll(ids));
  }

  bool isFavorite(int songId) => favoriteIds.contains(songId);

  Future<void> toggle(SongModel song) async {
    if (favoriteIds.contains(song.id)) {
      favoriteIds.remove(song.id);
    } else {
      favoriteIds.add(song.id);
    }
    await _repo.toggleFavorite(song);
  }
}