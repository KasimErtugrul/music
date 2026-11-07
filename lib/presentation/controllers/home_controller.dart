import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';

class HomeController extends GetxController {
  /// [historySyncDebounce] test edilebilirlik içindir: canlı uygulama
  /// varsayılan 2 sn'lik sönümle hızlı parça atlamalarının sorgu
  /// patlamasına dönüşmesini engeller; testler sıfıra çeker.
  HomeController(
    this._statsRepo,
    this._favRepo,
    this._historyRepo,
    this._libraryRepo, {
    this.historySyncDebounce = const Duration(seconds: 2),
  });

  final Duration historySyncDebounce;

  final StatsRepository _statsRepo;
  final FavoriteRepository _favRepo;
  final HistoryRepository _historyRepo;
  final LibraryRepository _libraryRepo;

  final recentlyAdded = <SongModel>[].obs;
  final mostPlayed = <SongModel>[].obs;
  final neverPlayed = <SongModel>[].obs;
  final favoriteCount = 0.obs;
  final isLoading = true.obs;

  final featuredAlbums = <AlbumModel>[].obs;
  final recentlyPlayedAlbums = <AlbumModel>[].obs;
  final favoriteSongs = <SongModel>[].obs;
  final randomDiscoveries = <SongModel>[].obs;

  /// Şarkı başına toplam çalınma sayısı (En Çok Çalınanlar rozetleri için).
  final mostPlayedCounts = <int, int>{}.obs;

  final _random = Random();
  StreamSubscription<List<int>>? _favSub;

  // Bulgu 14: favori şarkı listesi yazımı için bayatlık kilidi (staleness
  // token). İki hızlı favori değişiminde _updateFavoriteSongs'un songs()
  // bekleyişi kesişir; eski listenin yazımı EN SON bitince favori şarkılar
  // bayat kalır. Son olay kazanır: her olay bir sıra numarası alır,
  // await bitiminde numara değişmişse yazım atılır. favoriteCount Rx'i
  // zaten senkron yazıldığı için kendini düzeltir; kilit LISTE yazımı içindir.
  int _favSyncEpoch = 0;

  // Bulgu 2: çalma geçmişi canlı izlenir. HistoryController (geçmiş
  // sayfası) zaten watchRecentHistory ile canlıyken ana sayfanın
  // geçmişten türeyen bölümleri yalnız pull-to-refresh ile
  // güncelleniyordu — her ~30 sn'de bir recordPlay yazıldığı halde
  // «Son Çalınan Albümler / En Çok Çalınanlar / çalma sayısı rozetleri»
  // bayat kalıyordu. Abonelik o boşluğu kapatır.
  StreamSubscription<List<SongModel>>? _historySub;
  Timer? _historyDebounce;
  List<SongModel> _latestHistory = const <SongModel>[];

  @override
  void onInit() {
    super.onInit();
    _favSub = _favRepo.watchFavoriteIds().listen((ids) async {
      favoriteCount.value = ids.length;
      // Bulgu 14: hata sözleşmesi — loadAll ile aynı (logla, abonelik
      // canlı kalır). Dinleyici async'i hatasız bırakmak işlenmemiş
      // async hata olarak yutulurdu; ayrıca hata sonraki olayı da
      // engellemez, sonraki olay listeyi tazeler.
      final epoch = ++_favSyncEpoch;
      try {
        await _updateFavoriteSongs(ids, null, epoch);
      } catch (e, st) {
        AppLog.error(e, st, source: 'HomeController.watchFavoriteIds');
      }
    });
    _historySub = _historyRepo.watchRecentHistory(limit: 30).listen((history) {
      _latestHistory = history;
      _scheduleHistorySync();
    });
    loadAll();
  }

  /// Bulgu 2: sönümleme — recordPlay hızlı atlamalarda art arda yazılır;
  /// her yazım için yeniden hesap yerine SON olaydan
  /// [historySyncDebounce] sonra tek hesap yapılır.
  void _scheduleHistorySync() {
    _historyDebounce?.cancel();
    _historyDebounce = Timer(historySyncDebounce, () {
      unawaited(_syncHistoryDerived());
    });
  }

  /// Bulgu 2: yalnız çalma geçmişinden türeyen bölümler yeniden hesaplanır.
  /// Kütüphane kaynaklı listeler (featuredAlbums, randomDiscoveries,
  /// recentlyAdded, neverPlayed) bilinçli olarak DOKUNULMAZ: onlar
  /// loadAll'ın rastgele karıştırmasına bağlıdır; her recordPlay'de
  /// yeniden karıştırılsalar carousel sürekli yer değiştirirdi.
  Future<void> _syncHistoryDerived() async {
    try {
      final results = await Future.wait([
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.mostPlayed),
        _statsRepo.getMostPlayedCounts(limit: 100),
        _libraryRepo.albums(),
      ]);
      final most = results[0] as List<SongModel>;
      final counts = results[1] as Map<int, int>;
      final allAlbums = results[2] as List<AlbumModel>;

      mostPlayed.assignAll(most.take(10));
      mostPlayedCounts.assignAll(counts);
      _updateRecentlyPlayedAlbums(allAlbums, _latestHistory);
    } catch (e, st) {
      AppLog.error(e, st, source: 'HomeController._syncHistoryDerived');
    }
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.recentlyAdded),
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.mostPlayed),
        _statsRepo.getSmartPlaylist(SmartPlaylistKeys.neverPlayed),
        _libraryRepo.albums(),
        _libraryRepo.songs(),
        _statsRepo.getMostPlayedCounts(limit: 100),
      ]);

      final recent = results[0] as List<SongModel>;
      final most = results[1] as List<SongModel>;
      final never = results[2] as List<SongModel>;
      final allAlbums = results[3] as List<AlbumModel>;
      final allSongs = results[4] as List<SongModel>;
      final counts = results[5] as Map<int, int>;

      recentlyAdded.assignAll(recent.take(10));
      mostPlayed.assignAll(most.take(10));
      neverPlayed.assignAll(never.take(10));
      mostPlayedCounts.assignAll(counts);

      final shuffledAlbums = List<AlbumModel>.from(allAlbums)..shuffle(_random);
      featuredAlbums.assignAll(shuffledAlbums.take(8));

      final shuffledNever = List<SongModel>.from(never)..shuffle(_random);
      randomDiscoveries.assignAll(shuffledNever.take(10));

      await _loadRecentlyPlayedAlbums(allAlbums);

      final favIds = await _favRepo.watchFavoriteIds().first;
      favoriteCount.value = favIds.length;
      await _updateFavoriteSongs(favIds, allSongs);
    } catch (e, st) {
      AppLog.error(e, st, source: 'HomeController.loadAll');
    } finally {
      isLoading.value = false;
    }
  }

  /// loadAll için: geçmişin anlık görüntüsünü çekip albüm türetmesini
  /// çalıştırır (Bulgu 2 ile aynı hesap, tek kaynak:
  /// [_updateRecentlyPlayedAlbums]).
  Future<void> _loadRecentlyPlayedAlbums(List<AlbumModel> allAlbums) async {
    try {
      final history = await _historyRepo.watchRecentHistory(limit: 30).first;
      _updateRecentlyPlayedAlbums(allAlbums, history);
    } catch (_) {}
  }

  void _updateRecentlyPlayedAlbums(
    List<AlbumModel> allAlbums,
    List<SongModel> history,
  ) {
    final albumById = {for (final a in allAlbums) a.id: a};
    final seen = <int>{};
    final albums = <AlbumModel>[];
    for (final song in history) {
      final albumId = song.albumId;
      if (albumId == null || seen.contains(albumId)) continue;
      seen.add(albumId);
      final album = albumById[albumId];
      if (album != null) albums.add(album);
      if (albums.length >= 8) break;
    }
    recentlyPlayedAlbums.assignAll(albums);
  }

  Future<void> _updateFavoriteSongs(
    List<int> favIds, [
    List<SongModel>? cachedSongs,
    int? epoch,
  ]) async {
    if (favIds.isEmpty) {
      favoriteSongs.clear();
      return;
    }
    final allSongs = cachedSongs ?? await _libraryRepo.songs();
    // Bulgu 14: songs() beklenirken yeni bir favori olayı geldiyse
    // (sıra numarası arttıysa) bu yazım bayattır; son olayın yazımına
    // yer bırak. loadAll çağrısı epoch geçirmez: kendi anlık
    // görüntüsüyle yazar, mevcut sözleşme korunur.
    if (epoch != null && epoch != _favSyncEpoch) return;
    final songById = {for (final s in allSongs) s.id: s};
    final favs = <SongModel>[];
    for (final id in favIds) {
      final s = songById[id];
      if (s != null) favs.add(s);
    }
    favoriteSongs.assignAll(favs.take(10));
  }

  @override
  void onClose() {
    _favSub?.cancel();
    _historySub?.cancel();
    _historyDebounce?.cancel();
    super.onClose();
  }
}