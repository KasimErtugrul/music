import 'dart:async';

import 'package:get/get.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class StatsController extends GetxController {
  /// [historySyncDebounce] test edilebilirlik içindir: canlı uygulama
  /// varsayılan 2 sn'lik sönümle hızlı parça atlamalarının sorgu
  /// patlamasına dönüşmesini engeller; testler sıfıra çeker.
  StatsController(
    this._repo,
    this._historyRepo, {
    this.historySyncDebounce = const Duration(seconds: 2),
  });

  final StatsRepository _repo;
  final HistoryRepository _historyRepo;
  final Duration historySyncDebounce;

  final stats = Rxn<PlayStatsModel>();
  final recent = <RecentPlay>[].obs;
  final isLoading = true.obs;

  /// Dönem seçimi: 0 = Bu hafta, 1 = Bu ay, 2 = Tüm zamanlar.
  final period = 2.obs;

  // Bulgu 3: istatistik canlı senkronu. Dönem denetleyici tek seferlik
  // yüklüyordu (onInit + setPeriod); çalma sırasında her ~30 sn'de bir
  // recordPlay geçmişi değiştirdiği halde sayfa bayat kalıyordu — yalnız
  // dönem değiştirmek veya geçmişi silmek tazeliyordu. Geçmiş sayfası
  // (HistoryController) zaten watchRecentHistory ile canlı olduğundan
  // iki sayfa birbirinden ayrışıyordu. Artık aynı yayın dinlenir:
  // geçmiş değişince sönümlü sessiz yeniden hesap çalışır.
  StreamSubscription<List<SongModel>>? _historySub;
  Timer? _syncDebounce;

  @override
  void onInit() {
    super.onInit();
    _historySub = _historyRepo.watchRecentHistory(limit: 30).listen((_) {
      _scheduleLiveSync();
    });
    loadStats();
  }

  /// Sönümleme: recordPlay hızlı atlamalarda art arda yazılır; her yazım
  /// için yeniden hesap yerine SON olaydan [historySyncDebounce] sonra
  /// tek hesap yapılır.
  void _scheduleLiveSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(historySyncDebounce, () {
      unawaited(_syncLive());
    });
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

  /// Kullanıcı görünürlüklü yükleme: spinner gösterilir.
  /// Bekleyen canlı senkron iptal edilir — loadStats zaten tüm veriyi
  /// aynı dönemle yeniden hesaplar; çift sorgu anlamsızdır.
  Future<void> loadStats() async {
    _syncDebounce?.cancel();
    isLoading.value = true;
    try {
      await _refresh();
    } finally {
      isLoading.value = false;
    }
  }

  /// Bulgu 3: arka plan canlı senkronu. Sayfa görünürken spinner
  /// flaşını önlemek için isLoading'e DOKUNMAZ; değerler sessizce
  /// değişir ve Obx'ler kendiliğinden tazelenir. Hata çalma akışını
  /// bozmamak için günlüğe yazılıp yutulur (sonraki olay yeniden dener).
  Future<void> _syncLive() async {
    try {
      await _refresh();
    } on Object catch (e, st) {
      AppLog.error(e, st, source: 'StatsController._syncLive');
    }
  }

  Future<void> _refresh() async {
    stats.value = await _repo.getStats(since: _periodStart());
    recent.assignAll(
      await _repo.getRecentPlays(window: const Duration(hours: 24)),
    );
  }

  @override
  void onClose() {
    _historySub?.cancel();
    _syncDebounce?.cancel();
    super.onClose();
  }
}
