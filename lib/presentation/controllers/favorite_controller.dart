import 'package:get/get.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';

class FavoriteController extends GetxController {
  FavoriteController(this._repo);
  final FavoriteRepository _repo;

  final favoriteIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _repo.watchFavoriteIds().listen((ids) {
      favoriteIds.assignAll(ids);
    });
  }

  bool isFavorite(int songId) => favoriteIds.contains(songId);

  Future<void> toggle(int songId) async {
    // UI'ı anında güncelle (optimistic update)
    if (favoriteIds.contains(songId)) {
      favoriteIds.remove(songId);
    } else {
      favoriteIds.add(songId);
    }
    await _repo.toggleFavorite(songId);
  }
}