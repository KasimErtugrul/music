import 'dart:async';

import 'package:get/get.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';

class HistoryController extends GetxController {
  HistoryController(this._repo);
  final HistoryRepository _repo;

  final history = <SongModel>[].obs;
  final isLoading = true.obs;

  /// Bulgu 15/16: LibraryController'daki hasError sözleşmesi. Watch akışı
  /// hata verirse (ör. DB bozulması) dinleyici onError'a düşer; hasError
  /// kullanıcıya görünen sinyal olur ve spinner sonsuza dek dönmez.
  final hasError = false.obs;

  /// Bulgu 16: abonelik saklanır; onClose'ta iptal edilmezse Get.reset()/
  /// test ortamında akış denetleyiciden uzun yaşar.
  StreamSubscription<List<SongModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchRecentHistory().listen(
      (songs) {
        history.assignAll(songs);
        isLoading.value = false;
      },
      // Bulgu 16: onError'suz dinleyicide akış hatası aboneliği öldürür —
      // geçmiş listesi ve isLoading true haliyle donar. onError ile
      // abonelik yaşar; Drift sonraki tablo olayında yeniden sorgular.
      onError: (Object e, StackTrace st) {
        AppLog.error(e, st, source: 'HistoryController.watchRecentHistory');
        hasError.value = true;
        isLoading.value = false;
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> clearHistory() => _repo.clearHistory();
}