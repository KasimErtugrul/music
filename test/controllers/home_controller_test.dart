// Bulgu 14: favori şarkı listesi bayatlık kilidi + hata sözleşmesi.
//
// Sözleşme: _favSub dinleyicisi async'ti ve _updateFavoriteSongs'un
// songs() bekleyişi iki hızlı favori değişiminde kesişiyordu; eski
// listenin yazımı EN SON bitince favori şarkılar bayat kalıyordu.
// Ayrıca dinleyicide try/catch yoktu: songs() hatası işlenmemiş async
// hata olarak yutuluyor, sonraki olayların tazelemesi de risk altındaydı.
// Artık son olay kazanır (sıra numarası) ve hata loadAll'la aynı
// sözleşmeyle (logla + abonelik canlı kalır) işlenir.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/controllers/home_controller.dart';

class _MockStatsRepository extends Mock implements StatsRepository {}

class _MockFavoriteRepository extends Mock implements FavoriteRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockLibraryRepository extends Mock implements LibraryRepository {}

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
  late _MockFavoriteRepository favRepo;
  late _MockHistoryRepository historyRepo;
  late _MockLibraryRepository libRepo;
  late StreamController<List<int>> favStream;
  late StreamController<List<SongModel>> historyStream;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0);
  });

  setUp(() {
    Get.testMode = true;
    statsRepo = _MockStatsRepository();
    favRepo = _MockFavoriteRepository();
    historyRepo = _MockHistoryRepository();
    libRepo = _MockLibraryRepository();

    favStream = StreamController<List<int>>.broadcast();
    historyStream = StreamController<List<SongModel>>.broadcast();

    when(() => favRepo.watchFavoriteIds()).thenAnswer((_) => favStream.stream);
    when(() => historyRepo.watchRecentHistory(limit: any(named: 'limit')))
        .thenAnswer((_) => historyStream.stream);
    when(() => statsRepo.getSmartPlaylist(any()))
        .thenAnswer((_) async => const <SongModel>[]);
    when(() => statsRepo.getMostPlayedCounts(limit: any(named: 'limit')))
        .thenAnswer((_) async => const <int, int>{});
    when(() => libRepo.albums()).thenAnswer((_) async => const <AlbumModel>[]);
    when(() => libRepo.songs()).thenAnswer((_) async => const <SongModel>[]);
  });

  tearDown(() async {
    await favStream.close();
    await historyStream.close();
    Get.reset();
  });

  Future<void> settle(HomeController ctrl) async {
    for (var i = 0; i < 500; i++) {
      if (!ctrl.isLoading.value) break;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  HomeController build() {
    final ctrl = HomeController(
      statsRepo,
      favRepo,
      historyRepo,
      libRepo,
      historySyncDebounce: Duration.zero,
    )..onInit();
    // loadAll'ın son adımı watchFavoriteIds().first bekler; boş olayla
    // açılış yüklemesini tamamla ki testler temiz bir başlangıç yapsın.
    favStream.add(const <int>[]);
    historyStream.add(const <SongModel>[]);
    return ctrl;
  }

  group('Bulgu 14: favori listesi bayatlık kilidi', () {
    test('yavaş songs() ile iki hızlı favori olayı: son olayın listesi kazanır',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);

      final song1 = _song(1);
      final song2 = _song(2);
      final gates = <Completer<List<SongModel>>>[
        Completer<List<SongModel>>(), // 1. olayın okuması (yavaş)
        Completer<List<SongModel>>(), // 2. olayın okuması (hızlı)
      ];
      var songsCall = 0;
      when(() => libRepo.songs()).thenAnswer((_) {
        final i = songsCall++;
        return i < gates.length
            ? gates[i].future
            : Future<List<SongModel>>.value(<SongModel>[song1, song2]);
      });

      favStream.add(<int>[1]); // 1. favori değişimi: okuma yolda, askıda
      await Future<void>.delayed(Duration.zero);
      expect(songsCall, 1);

      favStream.add(<int>[2]); // 2. favori değişimi
      await Future<void>.delayed(Duration.zero);
      expect(songsCall, 2);
      expect(ctrl.favoriteCount.value, 1); // rozet senkron doğru

      gates[1].complete(<SongModel>[song1, song2]); // 2. olayın okuması önce
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ctrl.favoriteSongs.map((s) => s.id), <int>[2]);

      gates[0].complete(<SongModel>[song1, song2]); // 1. olay GEÇ biter
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Kilit: bayat yazım atıldı; liste [1] ezilip dömedi.
      expect(ctrl.favoriteSongs.map((s) => s.id), <int>[2]);
    });

    test('favoriler boşalınca liste temizlenir; geç okuma yazamaz', () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);

      final slowGate = Completer<List<SongModel>>();
      var first = true;
      when(() => libRepo.songs()).thenAnswer((_) {
        if (first) {
          first = false;
          return slowGate.future;
        }
        return Future<List<SongModel>>.value(const <SongModel>[]);
      });

      favStream.add(<int>[1]); // okuma askıda
      await Future<void>.delayed(Duration.zero);

      favStream.add(const <int>[]); // favoriler boşaldı → anında temizlik
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.favoriteSongs, isEmpty);
      expect(ctrl.favoriteCount.value, 0);

      slowGate.complete(<SongModel>[_song(1)]); // 1. olayın okuması geç biter
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Kilit: boşalmış listeye bayat şarkı yazılamaz.
      expect(ctrl.favoriteSongs, isEmpty);
    });
  });

  group('Bulgu 14: hata sözleşmesi', () {
    test('songs() hatası dinleyiciyi öldürmez; sonraki olay listeyi tazeler',
        () async {
      final ctrl = build();
      addTearDown(ctrl.onClose);
      await settle(ctrl);

      when(() => libRepo.songs()).thenThrow(StateError('geçici'));
      favStream.add(<int>[1]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Hata loglandı ve yutuldu (işlenmemiş async hata yok — test yeşilse
      // catch çalışıyor); liste eski hâlinde kalır.
      expect(ctrl.favoriteSongs, isEmpty);

      // Abonelik canlı: sonraki olay listeyi tazeler.
      when(() => libRepo.songs())
          .thenAnswer((_) async => <SongModel>[_song(1)]);
      favStream.add(<int>[1]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ctrl.favoriteSongs.map((s) => s.id), <int>[1]);
    });
  });
}
