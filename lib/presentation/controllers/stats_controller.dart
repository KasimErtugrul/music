import 'package:get/get.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class StatsController extends GetxController {
  StatsController(this._repo);
  final StatsRepository _repo;

  final stats = Rxn<PlayStatsModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      stats.value = await _repo.getStats();
    } finally {
      isLoading.value = false;
    }
  }
}