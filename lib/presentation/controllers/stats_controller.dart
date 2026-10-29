import 'package:get/get.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class StatsController extends GetxController {
  StatsController(this._repo);
  final StatsRepository _repo;

  final stats = Rxn<PlayStatsModel>();
  final recent = <RecentPlay>[].obs;
  final isLoading = true.obs;

  /// Dönem seçimi: 0 = Bu hafta, 1 = Bu ay, 2 = Tüm zamanlar.
  final period = 2.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  /// Dönemin başlangıcını hesaplar (takvim bazlı).
  DateTime? _periodStart() {
    final now = DateTime.now();
    switch (period.value) {
      case 0:
        // Hafta başlangıcı: Pazartesi 00:00.
        final weekday = now.weekday; // 1 = Pazartesi
        final monday = now.subtract(Duration(days: weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case 1:
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
  }

  Future<void> setPeriod(int value) async {
    if (period.value == value) return;
    period.value = value;
    await loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      stats.value = await _repo.getStats(since: _periodStart());
      recent.assignAll(
        await _repo.getRecentPlays(window: const Duration(hours: 24)),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
