import 'dart:isolate';
import 'dart:typed_data';

import 'package:resonance/core/utils/locale_sorter.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';

enum SongSortField { title, artist, album, dateAdded, duration }
enum SortDirection { ascending, descending }

class SongSort {
  const SongSort({
    this.field = SongSortField.title,
    this.direction = SortDirection.ascending,
  });
  final SongSortField field;
  final SortDirection direction;
  bool get isDescending => direction == SortDirection.descending;
  @override
  bool operator ==(Object other) =>
      other is SongSort && other.field == field && other.direction == direction;
  @override
  int get hashCode => Object.hash(field, direction);
}

class LibrarySearchResult {
  const LibrarySearchResult({
    this.songs = const <SongModel>[],
    this.albums = const <AlbumModel>[],
    this.artists = const <ArtistModel>[],
  });
  static const LibrarySearchResult empty = LibrarySearchResult();
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  bool get isEmpty => songs.isEmpty && albums.isEmpty && artists.isEmpty;
}

/// Aşama 3: artımlı taramanın sonucu. [changed] yalnızca ham MediaStore
/// verisi gerçekten değiştiğinde doğrudur; sayılar tarama öncesi → sonrası
/// farkıdır (güncellenen şarkılar aynı MediaStore id ile korunur).
class LibraryScanDelta {
  const LibraryScanDelta({
    required this.changed,
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
    this.scannedFiles = 0,
  });

  final bool changed;
  final int added;
  final int updated;
  final int removed;

  /// Platform tarayıcıya bildirilen dosya sayısı (tetiklenmediyse 0).
  final int scannedFiles;

  @override
  String toString() =>
      'LibraryScanDelta(+$added ~$updated -$removed, scanned: $scannedFiles)';
}

abstract class LibraryRepository {
  Future<List<SongModel>> songs({SongSort sort = const SongSort()});
  Future<Map<String, int>> letterOffsets(SongSort sort);
  Future<List<AlbumModel>> albums({bool descending = false});
  Future<List<ArtistModel>> artists({bool descending = false});
  Future<List<GenreModel>> genres({bool descending = false});
  Future<List<FolderModel>> folders({String? parentPath});
  Future<List<SongModel>> songsInAlbum(int albumId);
  Future<List<SongModel>> songsOfArtist(int artistId);
  Future<List<AlbumModel>> albumsOfArtist(int artistId);
  Future<List<SongModel>> songsInGenre(String genreKey);
  Future<List<SongModel>> songsInFolder(String path, {bool recursive = false});
  Future<LibrarySearchResult> search(String query, {int limitPerGroup = 100});
  Future<void> rescan();

  /// Aşama 3: artımlı tarama. MediaStore'u yeniden sorgular; ham veri
  /// değişmediyse indekse dokunmaz (değişmediğinde maliyet = tek sorgu).
  /// [triggerPlatformScan] doğruysa önce bilinen müzik klasörleri platform
  /// tarayıcıya bildirilir (USB kopyası yeni dosyalar için). Değişiklik
  /// varsa indeks güncel tercihlerlerle (min. süre, gizli klasörler)
  /// atomik olarak yeniden kurulur.
  Future<LibraryScanDelta> incrementalScan({bool triggerPlatformScan = false});

  Future<Uint8List?> artwork(int songId, {int size = 200});
}

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(
    this._source,
    this._prefs,
    this._excludedRepo, {
    this.useIsolate = true,
  });

  final DeviceMediaDataSource _source;
  final PreferencesRepository _prefs;
  final ExcludedFolderRepository _excludedRepo;  // YENİ
  final bool useIsolate;

  _LibraryIndex? _index;
  Future<_LibraryIndex>? _loading;
  final Map<SongSort, List<int>> _orders = {};
  final Map<SongSort, List<SongModel>> _sorted = {};

  // Görev 4.3: min. süre filtresi ARTIK İNDEKS KURULUMUNDA uygulanır.
  // İndeks hangi filtre değeriyle kurulduysa o tutulur; ayar değiştiğinde
  // indeks _rawSongs ham verisinden yeniden kurulur (MediaStore tekrar
  // sorgulanmaz). Böylece şarkı listesi, albüm/sanatçı/tür/klasör sayaçları
  // ve detay sayfaları hep aynı filtreli veri kümesini görür. (Ek-A'nın
  // yalnızca songs() çıktısına süzen yaklaşımının yerini aldı.)
  int _indexMinDurSec = 0;
  List<SongModel>? _rawSongs;
  List<String>? _excludedPaths;

  Future<_LibraryIndex> _ensureIndex() {
    final ready = _index;
    if (ready != null) return Future<_LibraryIndex>.value(ready);
    return _loading ??= _load();
  }

  Future<_LibraryIndex> _load() async {
    try {
      final songs = await _source.querySongs();

      // YENİ: Gizli klasörleri DB'den çek
      final excludedFolders = await _excludedRepo.getExcludedFolders();
      final excludedPaths = excludedFolders.map((f) => f.path).toList();

      // Görev 4.3: indeks, güncel min. süre tercihiyle baştan filtreli kurulur.
      final minDurSec = (await _prefs.loadLibrary()).minDurationSeconds;
      _rawSongs = songs;
      _excludedPaths = excludedPaths;
      _indexMinDurSec = minDurSec;

      final index = useIsolate
          ? await _buildIndexInIsolate(songs, excludedPaths, minDurSec)
          : _buildIndex(songs, excludedPaths, minDurSec);
      _orders.clear();
      _sorted.clear();
      _index = index;
      return index;
    } finally {
      _loading = null;
    }
  }

  @override
  Future<void> rescan() async {
    _index = null;
    _orders.clear();
    _sorted.clear();
    final pending = _loading;
    if (pending != null) {
      try {
        await pending;
      } on Object {}
      _index = null;
      _orders.clear();
      _sorted.clear();
    }
    await _ensureFreshIndex();
  }

  @override
  Future<LibraryScanDelta> incrementalScan({
    bool triggerPlatformScan = false,
  }) async {
    var scannedFiles = 0;
    if (triggerPlatformScan) {
      scannedFiles = await _platformScanKnownFolders();
    }
    final fresh = await _source.querySongs();
    final current = _rawSongs;
    // İlk yükleme henüz tamamlanmadıysa farkı hesaplayamayız; açılış
    // yüklemesi zaten taze MediaStore verisi getirecektir.
    if (current == null) {
      return LibraryScanDelta(changed: false, scannedFiles: scannedFiles);
    }
    final delta = _diffSongs(current, fresh);
    if (!delta.changed) {
      return LibraryScanDelta(changed: false, scannedFiles: scannedFiles);
    }
    // Ham veriyi tazele, indeksi güncel tercihlerlerle yeniden kur. Gizli
    // klasör listesi her taramada yeniden okunur; kullanıcı ara vermede
    // yaptığı dışlama değişiklikleri de burada devreye girer. Geçiş
    // atomiktir: yeni indeks hazır olana dek tüketiciler eskisini okur.
    final excludedPaths = (await _excludedRepo.getExcludedFolders())
        .map((f) => f.path)
        .toList(growable: false);
    final minDurSec = (await _prefs.loadLibrary()).minDurationSeconds;
    final index = useIsolate
        ? await _buildIndexInIsolate(fresh, excludedPaths, minDurSec)
        : _buildIndex(fresh, excludedPaths, minDurSec);
    _rawSongs = fresh;
    _excludedPaths = excludedPaths;
    _indexMinDurSec = minDurSec;
    _index = index;
    _orders.clear();
    _sorted.clear();
    return LibraryScanDelta(
      changed: true,
      added: delta.added,
      updated: delta.updated,
      removed: delta.removed,
      scannedFiles: scannedFiles,
    );
  }

  /// Görev 4.3: indeksi güncel min. süre tercihiyle taze tutar. Tüm liste,
  /// sayaç ve detay metotları bunu kullanır; ayar değiştiğinde indeks ham
  /// veriden hızlıca yeniden kurulur (cihaz yeniden sorgulanmaz).
  Future<_LibraryIndex> _ensureFreshIndex() async {
    final minDurSec = (await _prefs.loadLibrary()).minDurationSeconds;
    if (_index != null && minDurSec != _indexMinDurSec) {
      await _rebuildIndexWithMinDuration(minDurSec);
    }
    return _ensureIndex();
  }

  /// İndeksi aynı ham veri üzerinde yeni filtre değeriyle yeniden kurar.
  /// Geçiş atomiktir: yeni indeks hazır olana kadar tüketiciler eski indeksi
  /// okumaya devam eder, null görmezler.
  Future<void> _rebuildIndexWithMinDuration(int minDurSec) async {
    final raw = _rawSongs;
    final excluded = _excludedPaths;
    if (raw == null || excluded == null) {
      // Ham veri yok (ilk yük tamamlanmadı): kalın yol — tam rescan.
      await rescan();
      return;
    }
    final index = useIsolate
        ? await _buildIndexInIsolate(raw, excluded, minDurSec)
        : _buildIndex(raw, excluded, minDurSec);
    _indexMinDurSec = minDurSec;
    _index = index;
    _orders.clear();
    _sorted.clear();
  }

  List<int> _orderFor(_LibraryIndex index, SongSort sort) {
    final cached = _orders[sort];
    if (cached != null) return cached;

    final songs = index.songs;
    final dir = sort.isDescending ? -1 : 1;
    final order = List<int>.generate(songs.length, (i) => i);

    int byTitle(int a, int b) {
      final c = index.titleKeys[a].compareTo(index.titleKeys[b]);
      return c != 0 ? c : songs[a].id.compareTo(songs[b].id);
    }

    int nullable(String? a, String? b, int d) {
      if (a == null) return b == null ? 0 : 1;
      if (b == null) return -1;
      return d * a.compareTo(b);
    }

    switch (sort.field) {
      case SongSortField.title:
        order.sort((a, b) {
          final c = dir * index.titleKeys[a].compareTo(index.titleKeys[b]);
          return c != 0 ? c : songs[a].id.compareTo(songs[b].id);
        });
      case SongSortField.artist:
        order.sort((a, b) {
          var c = nullable(index.artistKeys[a], index.artistKeys[b], dir);
          if (c != 0) return c;
          c = nullable(index.albumKeys[a], index.albumKeys[b], 1);
          if (c != 0) return c;
          return byTitle(a, b);
        });
      case SongSortField.album:
        order.sort((a, b) {
          var c = nullable(index.albumKeys[a], index.albumKeys[b], dir);
          if (c != 0) return c;
          c = nullable(index.artistKeys[a], index.artistKeys[b], 1);
          if (c != 0) return c;
          return byTitle(a, b);
        });
      case SongSortField.dateAdded:
        order.sort((a, b) {
          final ma = songs[a].dateAdded?.millisecondsSinceEpoch ?? 0;
          final mb = songs[b].dateAdded?.millisecondsSinceEpoch ?? 0;
          final c = dir * ma.compareTo(mb);
          return c != 0 ? c : byTitle(a, b);
        });
      case SongSortField.duration:
        order.sort((a, b) {
          final c = dir * songs[a].durationMs.compareTo(songs[b].durationMs);
          return c != 0 ? c : byTitle(a, b);
        });
    }
    _orders[sort] = order;
    return order;
  }

  @override
  Future<List<SongModel>> songs({SongSort sort = const SongSort()}) async {
    // Görev 4.3: filtre indeks düzeyinde uygulandığı için burada ek süzme
    // gerekmez; _ensureFreshIndex, ayar değişiminde indeksi yeniden kurar.
    final index = await _ensureFreshIndex();

    final cached = _sorted[sort];
    if (cached != null) return cached;

    final order = _orderFor(index, sort);

    final result = List<SongModel>.unmodifiable(
        <SongModel>[for (final i in order) index.songs[i]]);
    _sorted[sort] = result;
    return result;
  }

  @override
  Future<Map<String, int>> letterOffsets(SongSort sort) async {
    final index = await _ensureFreshIndex();
    final List<String?> keys;
    switch (sort.field) {
      case SongSortField.title:
        keys = index.titleKeys;
      case SongSortField.artist:
        keys = index.artistKeys;
      case SongSortField.album:
        keys = index.albumKeys;
      case SongSortField.dateAdded:
      case SongSortField.duration:
        return const <String, int>{};
    }
    final order = _orderFor(index, sort);
    final result = <String, int>{};
    for (var pos = 0; pos < order.length; pos++) {
      final key = keys[order[pos]];
      final letter = key == null
          ? LocaleSorter.otherIndex
          : LocaleSorter.indexLetterOfKey(key);
      result.putIfAbsent(letter, () => pos);
    }
    return result;
  }

  List<SongModel> _songsByTitle(_LibraryIndex index, Iterable<int> indexes) {
    final list = indexes.toList(growable: false)
      ..sort((a, b) {
        final c = index.titleKeys[a].compareTo(index.titleKeys[b]);
        return c != 0 ? c : index.songs[a].id.compareTo(index.songs[b].id);
      });
    return List<SongModel>.unmodifiable(
        [for (final i in list) index.songs[i]]);
  }

  @override
  Future<List<AlbumModel>> albums({bool descending = false}) async {
    final index = await _ensureFreshIndex();
    return List.unmodifiable(_orderByName<AlbumModel>(
        index.albums, (a) => a.title, descending: descending));
  }

  @override
  Future<List<ArtistModel>> artists({bool descending = false}) async {
    final index = await _ensureFreshIndex();
    return List.unmodifiable(_orderByName<ArtistModel>(
        index.artists, (a) => a.name, descending: descending));
  }

  @override
  Future<List<GenreModel>> genres({bool descending = false}) async {
    final index = await _ensureFreshIndex();
    return List.unmodifiable(_orderByName<GenreModel>(
        index.genres, (g) => g.name, descending: descending));
  }

  @override
  Future<List<SongModel>> songsInAlbum(int albumId) async {
    final index = await _ensureFreshIndex();
    return _songsByTitle(index, index.songsByAlbum[albumId] ?? const []);
  }

  @override
  Future<List<SongModel>> songsOfArtist(int artistId) async {
    final index = await _ensureFreshIndex();
    return _songsByTitle(index, index.songsByArtist[artistId] ?? const []);
  }

  @override
  Future<List<AlbumModel>> albumsOfArtist(int artistId) async {
    final index = await _ensureFreshIndex();
    final ids = index.albumIdsByArtist[artistId] ?? const <int>[];
    final models = <AlbumModel>[
      for (final id in ids)
        if (index.albumById[id] != null) index.albumById[id]!
    ];
    return List.unmodifiable(
        _orderByName<AlbumModel>(models, (a) => a.title));
  }

  @override
  Future<List<SongModel>> songsInGenre(String genreKey) async {
    final index = await _ensureFreshIndex();
    return _songsByTitle(index, index.songsByGenre[genreKey] ?? const []);
  }

  @override
  Future<List<FolderModel>> folders({String? parentPath}) async {
    final index = await _ensureFreshIndex();
    final paths = parentPath == null
        ? index.rootFolders
        : (index.childFolders[parentPath] ?? const <String>[]);
    final models = <FolderModel>[for (final p in paths) index.folders[p]!];
    return List.unmodifiable(
        _orderByName<FolderModel>(models, (f) => f.name));
  }

  @override
  Future<List<SongModel>> songsInFolder(String path, {bool recursive = false}) async {
    final index = await _ensureFreshIndex();
    if (!recursive) {
      return _songsByTitle(index, index.songsByFolder[path] ?? const []);
    }
    final prefix = '$path/';
    final collected = <int>[];
    index.songsByFolder.forEach((dir, indexes) {
      if (dir == path || dir.startsWith(prefix)) collected.addAll(indexes);
    });
    return _songsByTitle(index, collected);
  }

  @override
  Future<LibrarySearchResult> search(String query, {int limitPerGroup = 100}) async {
    final key = LocaleSorter.searchKey(query.trim());
    final tokens = key
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return LibrarySearchResult.empty;

    final index = await _ensureFreshIndex();
    bool matches(String text) => tokens.every(text.contains);

    final songs = <SongModel>[];
    for (final i in _orderFor(index, const SongSort())) {
      if (matches(index.searchKeys[i])) {
        songs.add(index.songs[i]);
        if (songs.length >= limitPerGroup) break;
      }
    }
    final albums = <AlbumModel>[];
    for (var i = 0; i < index.albums.length; i++) {
      if (index.albums[i].isUnknown) continue;
      if (matches(index.albumSearchKeys[i])) {
        albums.add(index.albums[i]);
        if (albums.length >= limitPerGroup) break;
      }
    }
    final artists = <ArtistModel>[];
    for (var i = 0; i < index.artists.length; i++) {
      if (index.artists[i].isUnknown) continue;
      if (matches(index.artistSearchKeys[i])) {
        artists.add(index.artists[i]);
        if (artists.length >= limitPerGroup) break;
      }
    }
    return LibrarySearchResult(
      songs: List.unmodifiable(songs),
      albums: List.unmodifiable(albums),
      artists: List.unmodifiable(artists),
    );
  }

  @override
  Future<Uint8List?> artwork(int songId, {int size = 200}) =>
      _source.queryArtwork(songId, size: size);

  // ---------- Aşama 3: artımlı tarama yardımcıları ----------

  /// Tarama kökü olarak gönderilecek klasör sayısı sınırı. _reduceToRoots
  /// ile indirgeme sonrası hâlâ bu sayıyı aşan kütüphanelerde (çok sayıda
  /// bağımsız klasör) kök listesi kırpılır; standart Müzik klasörü yine de
  /// Kotlin tarafında her zaman taranır.
  static const int _maxScanRoots = 64;

  /// Bilinen müzik klasörlerini platform tarayıcıya bildirir. Şarkı üst
  /// dizinleri ortak köklere indirgenir (/a/b ve /a/b/c → /a/b); standart
  /// Müzik/Download klasörlerini Kotlin tarafı ekler.
  Future<int> _platformScanKnownFolders() async {
    final raw = _rawSongs;
    if (raw == null || raw.isEmpty) return 0;
    // Üst dizin sondaki '/' OLMADAN alınır: substring(0, lastIndexOf('/'))
    // (/Music/a.mp3 → /Music). Eski +1 + trimRight() sürümü yanıltıcıydı;
    // trimRight yalnızca boşluk kırptığı için '/Music/' kökte kalıyor ve
    // _reduceToRoots içindeki startsWith(kök + '/') karşılaştırması hiç
    // tutmuyordu. Kök dizinde duran dosyalarda (ör. /a.mp3) sonuç '' olur
    // ve aşağıdaki removeWhere zaten eler.
    final parents = <String>{
      for (final s in raw)
        if (s.path.contains('/')) s.path.substring(0, s.path.lastIndexOf('/')),
    }..removeWhere((p) => p.isEmpty || p.length < 2);
    if (parents.isEmpty) return 0;
    final roots = _reduceToRoots(parents);
    final capped = roots.length > _maxScanRoots
        ? roots.sublist(0, _maxScanRoots)
        : roots;
    try {
      return await _source.triggerMediaScan(capped);
    } on Object {
      return 0;
    }
  }

  /// İki ham listeyi MediaStore id bazında karşılaştırır; kimlikler aynı
  /// kalıp içerik değişen şarkılar "güncellenmiş" sayılır.
  static LibraryScanDelta _diffSongs(
    List<SongModel> current,
    List<SongModel> fresh,
  ) {
    final currentFp = <int, int>{
      for (final s in current) s.id: _fingerprintOf(s),
    };
    final freshFp = <int, int>{
      for (final s in fresh) s.id: _fingerprintOf(s),
    };
    var added = 0;
    var updated = 0;
    var removed = 0;
    freshFp.forEach((id, fp) {
      final old = currentFp[id];
      if (old == null) {
        added++;
      } else if (old != fp) {
        updated++;
      }
    });
    currentFp.forEach((id, _) {
      if (!freshFp.containsKey(id)) removed++;
    });
    // id tekrarı gibi olası bozukluklarda uzunluk farkı da değişiklik sayılır.
    final changed = added != 0 ||
        updated != 0 ||
        removed != 0 ||
        current.length != fresh.length;
    return LibraryScanDelta(
      changed: changed,
      added: added,
      updated: updated,
      removed: removed,
    );
  }

  /// Şarkının karşılaştırma parmak izi. SongModel.== yalnızca (id, path)
  /// karşılaştırdığı için yeterli değildir; başlık/süre/boyut/tarih gibi
  /// tüm kullanıcıya görünen alanlar parmak izine katılır.
  static int _fingerprintOf(SongModel s) => Object.hash(
        s.id,
        s.uri,
        s.path,
        s.title,
        s.artist,
        s.album,
        s.genre,
        s.albumId,
        s.artistId,
        s.durationMs,
        s.sizeBytes,
        s.dateAdded?.millisecondsSinceEpoch,
      );

  /// Sıralanmış yolları ortak köklere indirger: atası listede olan yol
  /// atlanır (kök zaten alt ağacını kapsar). Sondaki '/' önce normalleştirilir
  /// (/a/b/ ile /a/b aynı kök sayılır; kök '/' kendisi korunur); aksi halde
  /// '/a/b/' + '/' öneki '/a/b//' olur ve alt klasörler indirgenemezdi.
  /// Girdinin sıralanmış olması yeterli; ata yollar sözcük sıralamasında
  /// öncedir.
  static List<String> _reduceToRoots(Iterable<String> paths) {
    final normalized = <String>{
      for (final p in paths)
        if (p.length > 1 && p.endsWith('/')) p.substring(0, p.length - 1) else p,
    }.toList()
      ..sort();
    final roots = <String>[];
    for (final p in normalized) {
      if (roots.isNotEmpty && p.startsWith('${roots.last}/')) continue;
      roots.add(p);
    }
    return roots;
  }
}

// ---------- Isolate ----------

Future<_LibraryIndex> _buildIndexInIsolate(
        List<SongModel> songs,
        List<String> excludedPaths,
        int minDurationSeconds) =>
    Isolate.run<_LibraryIndex>(
        () => _buildIndex(songs, excludedPaths, minDurationSeconds));

class _LibraryIndex {
  _LibraryIndex({
    required this.songs,
    required this.titleKeys,
    required this.artistKeys,
    required this.albumKeys,
    required this.searchKeys,
    required this.albums,
    required this.albumSearchKeys,
    required this.albumById,
    required this.artists,
    required this.artistSearchKeys,
    required this.genres,
    required this.songsByAlbum,
    required this.songsByArtist,
    required this.songsByGenre,
    required this.albumIdsByArtist,
    required this.folders,
    required this.songsByFolder,
    required this.childFolders,
    required this.rootFolders,
  });

  final List<SongModel> songs;
  final List<String> titleKeys;
  final List<String?> artistKeys;
  final List<String?> albumKeys;
  final List<String> searchKeys;
  final List<AlbumModel> albums;
  final List<String> albumSearchKeys;
  final Map<int, AlbumModel> albumById;
  final List<ArtistModel> artists;
  final List<String> artistSearchKeys;
  final List<GenreModel> genres;
  final Map<int, List<int>> songsByAlbum;
  final Map<int, List<int>> songsByArtist;
  final Map<String, List<int>> songsByGenre;
  final Map<int, List<int>> albumIdsByArtist;
  final Map<String, FolderModel> folders;
  final Map<String, List<int>> songsByFolder;
  final Map<String, List<String>> childFolders;
  final List<String> rootFolders;
}

int _albumIdOf(SongModel s) =>
    (s.album != null && s.albumId != null) ? s.albumId! : AlbumModel.unknownId;

int _artistIdOf(SongModel s) => (s.artist != null && s.artistId != null)
    ? s.artistId! : ArtistModel.unknownId;

final RegExp _volumeRe = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)');

String _volumeRootOf(String dir) {
  final m = _volumeRe.firstMatch(dir);
  if (m != null) return m.group(0)!;
  final slash = dir.indexOf('/', 1);
  return slash < 0 ? dir : dir.substring(0, slash);
}

String? _mostFrequent(Map<String, int> counts) {
  String? best;
  var bestCount = 0;
  counts.forEach((value, count) {
    if (count > bestCount) {
      best = value;
      bestCount = count;
    }
  });
  return best;
}

List<T> _orderByName<T>(
  Iterable<T> items,
  String? Function(T item) name, {
  bool descending = false,
}) {
  final known = <(String, T)>[];
  final unknown = <T>[];
  for (final item in items) {
    final n = name(item);
    if (n == null) {
      unknown.add(item);
    } else {
      known.add((LocaleSorter.collationKey(n), item));
    }
  }
  known.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return descending ? -c : c;
  });
  return [for (final e in known) e.$2, ...unknown];
}

_LibraryIndex _buildIndex(
  List<SongModel> songs,
  List<String> excludedPaths,
  int minDurationSeconds,
) {
  // Görev 4.3: min. süre filtresi indeks girişinde uygulanır; böylece
  // albüm/sanatçı/tür/klasör sayaçları ve detay listeleri de aynı kümeden
  // beslenir (önceden yalnızca songs() çıktısı süzülüyordu).
  if (minDurationSeconds > 0) {
    final minMs = minDurationSeconds * 1000;
    songs = songs.where((s) => s.durationMs >= minMs).toList(growable: false);
  }

  // YENİ: Gizli klasör filtresi
  if (excludedPaths.isNotEmpty) {
    songs = songs.where((s) {
      for (final p in excludedPaths) {
        if (s.path.startsWith(p)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  final n = songs.length;
  final titleKeys = List<String>.filled(n, '');
  final artistKeys = List<String?>.filled(n, null);
  final albumKeys = List<String?>.filled(n, null);
  final searchKeys = List<String>.filled(n, '');

  final byAlbum = <int, List<int>>{};
  final byArtist = <int, List<int>>{};
  final byGenre = <String, List<int>>{};
  final genreNames = <String, String>{};
  final directByFolder = <String, List<int>>{};
  final folderCount = <String, int>{};
  final folderDuration = <String, int>{};

  for (var i = 0; i < n; i++) {
    final s = songs[i];
    final artist = s.artist;
    final album = s.album;
    final genre = s.genre;

    titleKeys[i] = LocaleSorter.collationKey(s.title);
    if (artist != null) artistKeys[i] = LocaleSorter.collationKey(artist);
    if (album != null) albumKeys[i] = LocaleSorter.collationKey(album);
    searchKeys[i] = LocaleSorter.searchKey(
      '${s.title}\u0001${artist ?? ''}\u0001${album ?? ''}',
    );

    (byAlbum[_albumIdOf(s)] ??= <int>[]).add(i);
    (byArtist[_artistIdOf(s)] ??= <int>[]).add(i);

    final genreKey = genre == null ? '' : LocaleSorter.lowerCase(genre);
    (byGenre[genreKey] ??= <int>[]).add(i);
    if (genre != null) genreNames.putIfAbsent(genreKey, () => genre);

    final path = s.path;
    final slash = path.lastIndexOf('/');
    if (slash > 0) {
      final dir = path.substring(0, slash);
      (directByFolder[dir] ??= <int>[]).add(i);
      final root = _volumeRootOf(dir);
      var cur = dir;
      while (true) {
        folderCount[cur] = (folderCount[cur] ?? 0) + 1;
        folderDuration[cur] = (folderDuration[cur] ?? 0) + s.durationMs;
        if (cur == root) break;
        final up = cur.lastIndexOf('/');
        if (up <= 0) break;
        cur = cur.substring(0, up);
      }
    }
  }

  final albumModels = <AlbumModel>[];
  byAlbum.forEach((id, idxs) {
    var duration = 0;
    final artistCounts = <String, int>{};
    for (final i in idxs) {
      duration += songs[i].durationMs;
      final a = songs[i].artist;
      if (a != null) artistCounts[a] = (artistCounts[a] ?? 0) + 1;
    }
    final unknown = id == AlbumModel.unknownId;
    albumModels.add(AlbumModel(
      id: id,
      title: unknown ? null : songs[idxs.first].album,
      artist: _mostFrequent(artistCounts),
      songCount: idxs.length,
      totalDurationMs: duration,
      artworkSongId: unknown ? null : songs[idxs.first].id,
    ));
  });
  final albums = _orderByName<AlbumModel>(albumModels, (a) => a.title);
  final albumById = <int, AlbumModel>{for (final a in albums) a.id: a};
  final albumSearchKeys = <String>[
    for (final a in albums)
      LocaleSorter.searchKey('${a.title ?? ''}\u0001${a.artist ?? ''}'),
  ];

  final albumIdsByArtist = <int, List<int>>{};
  final artistModels = <ArtistModel>[];
  byArtist.forEach((id, idxs) {
    var duration = 0;
    final albumIds = <int>{};
    for (final i in idxs) {
      duration += songs[i].durationMs;
      final albumId = _albumIdOf(songs[i]);
      if (albumId != AlbumModel.unknownId) albumIds.add(albumId);
    }
    albumIdsByArtist[id] = albumIds.toList(growable: false);
    final unknown = id == ArtistModel.unknownId;
    artistModels.add(ArtistModel(
      id: id,
      name: unknown ? null : songs[idxs.first].artist,
      songCount: idxs.length,
      albumCount: albumIds.length,
      totalDurationMs: duration,
      artworkSongId: unknown ? null : songs[idxs.first].id,
    ));
  });
  final artists = _orderByName<ArtistModel>(artistModels, (a) => a.name);
  final artistSearchKeys = <String>[
    for (final a in artists) LocaleSorter.searchKey(a.name ?? ''),
  ];

  final genreModels = <GenreModel>[];
  byGenre.forEach((key, idxs) {
    var duration = 0;
    for (final i in idxs) {
      duration += songs[i].durationMs;
    }
    genreModels.add(GenreModel(
      key: key,
      name: genreNames[key],
      songCount: idxs.length,
      totalDurationMs: duration,
      artworkSongId: key.isEmpty ? null : songs[idxs.first].id,
    ));
  });
  final genres = _orderByName<GenreModel>(genreModels, (g) => g.name);

  final folders = <String, FolderModel>{};
  final childFolders = <String, List<String>>{};
  final rootFolders = <String>[];
  folderCount.forEach((path, count) {
    final slash = path.lastIndexOf('/');
    final isRoot = _volumeRootOf(path) == path;
    folders[path] = FolderModel(
      path: path,
      name: path.substring(slash + 1),
      parentPath: isRoot ? null : path.substring(0, slash),
      songCount: count,
      directSongCount: directByFolder[path]?.length ?? 0,
      totalDurationMs: folderDuration[path] ?? 0,
      isVolumeRoot: isRoot,
    );
    if (isRoot) {
      rootFolders.add(path);
    } else {
      (childFolders[path.substring(0, slash)] ??= <String>[]).add(path);
    }
  });

  return _LibraryIndex(
    songs: songs,
    titleKeys: titleKeys,
    artistKeys: artistKeys,
    albumKeys: albumKeys,
    searchKeys: searchKeys,
    albums: albums,
    albumSearchKeys: albumSearchKeys,
    albumById: albumById,
    artists: artists,
    artistSearchKeys: artistSearchKeys,
    genres: genres,
    songsByAlbum: byAlbum,
    songsByArtist: byArtist,
    songsByGenre: byGenre,
    albumIdsByArtist: albumIdsByArtist,
    folders: folders,
    songsByFolder: directByFolder,
    childFolders: childFolders,
    rootFolders: rootFolders,
  );
}