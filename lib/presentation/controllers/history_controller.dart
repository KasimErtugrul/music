import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';

class HistoryController extends GetxController {
  HistoryController(this._repo);
  final HistoryRepository _repo;

  final history = <SongModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _repo.watchRecentHistory().listen((songs) {
      history.assignAll(songs);
      isLoading.value = false;
    });
  }

  Future<void> clearHistory() => _repo.clearHistory();
}