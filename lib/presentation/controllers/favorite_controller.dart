import 'dart:async';

import 'package:get/get.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';

class FavoriteController extends GetxController {
  FavoriteController(this._repo);
  final FavoriteRepository _repo;

  final favoriteIds = <int>{}.obs;

  /// Bulgu 16: abonelik saklanır; onClose'ta iptal edilir (Get.reset()/
  /// test/hot-restart'ta «ghost update» sızıntısı kapanır).
  StreamSubscription<List<int>>? _sub;

  @override
  void onInit() {
    super.onInit();
    // Bulgu 16: onError'suz dinleyicide akış hatası aboneliği öldürür ve
    // favori rozetleri uygulama yeniden başlayana dek donar. onError ile
    // abonelik yaşar; hata günlüğe yazılır, son bilinen küme korunur
    // (Drift sonraki tablo olayında yeniden sorgular).
    _sub = _repo.watchFavoriteIds().listen(
      (ids) => favoriteIds.assignAll(ids),
      onError: (Object e, StackTrace st) {
        AppLog.error(e, st, source: 'FavoriteController.watchFavoriteIds');
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  bool isFavorite(int songId) => favoriteIds.contains(songId);

  Future<void> toggle(SongModel song) async {
    final wasFavorite = favoriteIds.contains(song.id);
    if (wasFavorite) {
      favoriteIds.remove(song.id);
    } else {
      favoriteIds.add(song.id);
    }
    try {
      await _repo.toggleFavorite(song);
    } on Object {
      // Bulgu 11: DB yazımı patlarsa kalp eski tarafına döner. Watch
      // akışı hata durumunda emit üretmeyeceği için durum kendiliğinden
      // düzelmez; optimistik güncelleme + rollback sözleşmesi.
      if (wasFavorite) {
        favoriteIds.add(song.id);
      } else {
        favoriteIds.remove(song.id);
      }
      rethrow;
    }
  }
}