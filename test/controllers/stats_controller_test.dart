// Bulgu 3: istatistik denetleyicisi canlı senkron sözleşmesi.
//
// Sözleşme: StatsController tek seferlik yüklüyordu (onInit + setPeriod);
// çalma sırasında her ~30 sn'de bir recordPlay geçmişi değiştirdiği
// halde sayfa bayat kalıyordu. Artık watchRecentHistory yayını
// dinlenir: geçmiş değişince sönümlü SESSİZ yeniden hesap çalışır
// (isLoading'e dokunulmaz — sayfa görünürken spinner flaşı olmaz),
// dönem değişimi ise eski gibi spinner'lı loadStats'i kullanır.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';

class _MockStatsRepository extends Mock implements StatsRepository {}
class _MockHistoryRepository extends Mock implements HistoryRepository {}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Şarkı $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

void main() {
  late _MockStatsRepository statsRepo;
  late _MockHistoryRepository historyRepo;
  late StreamController<List<SongModel>> historyStream;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue('');
    registerFallbackValue(0);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2020));
  });

  setUp(() {
    Get.testMode = true;
    statsRepo = _MockStatsRepository();
    historyRepo = _MockHistoryRepository();

    historyStream = StreamController<List<SongModel>>.broadcast();

    when(() => historyRepo.watchRecentHistory(limit: any(named: 'limit')))
        .thenAnswer((_) => historyStream.stream);
    when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
      (_) async => const PlayStatsModel(
        totalPlays: 0,
        uniqueSongsPlayed: 0,
        topArtists: <String, int>{},
        topGenres: <String, int>{},
      ),
    );
    when(() => statsRepo.getRecentPlays(
          window: any(named: 'window'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => <RecentPlay>[]);
  });

  tearDown(() async {
    await historyStream.close();
    Get.reset();
  });

  Future<void> settle(StatsController ctrl) async {
    for (var i = 0; i < 500; i++) {
      if (!ctrl.isLoading.value) break;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // Bekleyen sıfır süreli sönüm zamanlayıcılarını boşalt.
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  StatsController build() => StatsController(
        statsRepo,
        historyRepo,
        historySyncDebounce: Duration.zero,
      )..onInit();

  group('Bulgu 3: canlı senkron', () {
    test('geçmiş yayını değişince SESSİZ yeniden hesaplar (spinner yok)',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      // Yeni çalma kaydı: istatistik 5, son çalmalar 1 kayıt oldu.
      final song = _song(1);
      when(() => statsRepo.getStats(since: any(named: 'since'))).thenAnswer(
        (_) async => const PlayStatsModel(
          totalPlays: 5,
          uniqueSongsPlayed: 1,
          topArtists: <String, int>{'Sanatçı': 5},
          topGenres: <String, int>{},
        ),
      );
      when(() => statsRepo.getRecentPlays(
            window: any(named: 'window'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => <RecentPlay>[
          RecentPlay(song: song, playedAt: DateTime(2026, 11, 7, 12)),
        ],
      );

      historyStream.add(<SongModel>[song]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(ctrl.stats.value?.totalPlays, 5);
      expect(ctrl.recent.length, 1);
      // Spinner FLAŞI YOK: arka plan senkronu isLoading'e dokunmaz.
      expect(ctrl.isLoading.value, isFalse);
      // Varsayılan dönem «tüm zamanlar» → since null ile hesaplanır.
      verify(() => statsRepo.getStats(since: null)).called(1);
    });

    test('hızlı ardışık yayınlar tek hesapta birleşir (sönümleme)', () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      final song = _song(1);
      // Aynı olay döngüsünde üç recordPlay yazımı.
      historyStream.add(<SongModel>[song]);
      historyStream.add(<SongModel>[song]);
      historyStream.add(<SongModel>[song]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => statsRepo.getStats(since: any(named: 'since'))).called(1);
      verify(() => statsRepo.getRecentPlays(
            window: any(named: 'window'),
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('setPeriod pencereyi değiştirir ve spinner\'lı yüklemeyi kullanır',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      await ctrl.setPeriod(0); // Bu hafta

      expect(ctrl.period.value, 0);
      final captured = verify(() => statsRepo.getStats(
            since: captureAny(named: 'since'),
          )).captured.single as DateTime?;
      // Hafta başlangıcı takvim bazlı bir anlıktır, null değil.
      expect(captured, isNotNull);
    });

    test('yeniden hesap hatası sayfayı çökertmez (günlük + eski değerler)',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);
      clearInteractions(statsRepo);

      final before = ctrl.stats.value;
      when(() => statsRepo.getStats(since: any(named: 'since')))
          .thenThrow(StateError('geçici'));

      historyStream.add(<SongModel>[_song(2)]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Hata yutulur: eski değerler durur, sayfa yaşar.
      expect(ctrl.stats.value, same(before));
      expect(ctrl.isLoading.value, isFalse);
    });
  });
}
