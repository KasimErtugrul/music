import 'dart:isolate';
import 'dart:typed_data';

import 'package:resonance/core/utils/locale_sorter.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';

enum SongSortField { title, artist, album, dateAdded, duration }

enum SortDirection { ascending, descending }

/// Şarkı listesi sıralaması (ad, sanatçı, albüm, tarih, süre; artan/azalan).
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

/// Arama sonuçları (şarkılar, albümler, sanatçılar).
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

/// Kütüphane verisi (şarkılar, albümler, sanatçılar, türler, klasörler).
///
/// Controller'lar yalnızca bu soyuta bağlanır. Albüm/sanatçı/tür/klasör
/// MediaStore'dan ayrıca okunmaz; tek şarkı sorgusundan türetilir.
abstract class LibraryRepository {
  /// Tüm şarkılar, istenen sıralamayla (Türkçe duyarlı). Sonuç değiştirilemez.
  Future<List<SongModel>> songs({SongSort sort = const SongSort()});

  /// Alfabetik indeks: harf → listedeki ilk konum. Yalnızca ad/sanatçı/albüm
  /// sıralamalarında anlamlıdır; tarih ve süre sıralamasında boş döner.
  Future<Map<String, int>> letterOffsets(SongSort sort);

  /// Ada göre sıralı; bilinmeyen her zaman sonda.
  Future<List<AlbumModel>> albums({bool descending = false});
  Future<List<ArtistModel>> artists({bool descending = false});
  Future<List<GenreModel>> genres({bool descending = false});

  /// [parentPath] null ise depolama kökleri; değilse doğrudan alt klasörler.
  Future<List<FolderModel>> folders({String? parentPath});

  /// Şarkılar ada göre sıralıdır (parça numarası henüz okunmuyor).
  Future<List<SongModel>> songsInAlbum(int albumId);
  Future<List<SongModel>> songsOfArtist(int artistId);
  Future<List<AlbumModel>> albumsOfArtist(int artistId);
  Future<List<SongModel>> songsInGenre(String genreKey);
  Future<List<SongModel>> songsInFolder(String path, {bool recursive = false});

  /// Büyük/küçük harf, Türkçe harf ve aksan duyarsız; birden çok kelime
  /// verilirse hepsi geçmelidir.
  Future<LibrarySearchResult> search(String query, {int limitPerGroup = 100});

  /// Kütüphaneyi cihazdan yeniden okur (önbelleği atar).
  Future<void> rescan();

  /// Şarkının kapağı (JPEG) veya null.
  Future<Uint8List?> artwork(int songId, {int size = 200});
}

/// [LibraryRepository] gerçeklemesi: şarkıları bir kez okur, indeksi (anahtarlar,
/// gruplar, klasör ağacı) arka plan isolate'inde kurar ve önbellekte tutur.
class LibraryRepositoryImpl implements LibraryRepository {
  /// [useIsolate] yalnızca testler içindir.
    LibraryRepositoryImpl(this._source, {this.useIsolate = true});


  final DeviceMediaDataSource _source;
  final bool useIsolate;

  _LibraryIndex? _index;
  Future<_LibraryIndex>? _loading;
  final Map<SongSort, List<int>> _orders = <SongSort, List<int>>{};
  final Map<SongSort, List<SongModel>> _sorted = <SongSort, List<SongModel>>{};

  Future<_LibraryIndex> _ensureIndex() {
    final ready = _index;
    if (ready != null) return Future<_LibraryIndex>.value(ready);
    return _loading ??= _load();
  }

  Future<_LibraryIndex> _load() async {
    try {
      final songs = await _source.querySongs();
      final index = useIsolate
          ? await _buildIndexInIsolate(songs)
          : _buildIndex(songs);
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
      // Süren okuma eski veriyle bitebilir; bitmesini bekleyip baştan oku.
      try {
        await pending;
      } on Object {
        // Hata yeni okumada yeniden denenir.
      }
      _index = null;
      _orders.clear();
      _sorted.clear();
    }
    await _ensureIndex();
  }

  // ---- Şarkılar ----

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

    // Bilinmeyen (null) her zaman sonda; yön yalnızca bilinenleri çevirir.
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
    final index = await _ensureIndex();
    final cached = _sorted[sort];
    if (cached != null) return cached;
    final order = _orderFor(index, sort);
    final result = List<SongModel>.unmodifiable(
      <SongModel>[for (final i in order) index.songs[i]],
    );
    _sorted[sort] = result;
    return result;
  }

  @override
  Future<Map<String, int>> letterOffsets(SongSort sort) async {
    final index = await _ensureIndex();
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
      <SongModel>[for (final i in list) index.songs[i]],
    );
  }

  // ---- Albüm / sanatçı / tür ----

  @override
  Future<List<AlbumModel>> albums({bool descending = false}) async {
    final index = await _ensureIndex();
    return List<AlbumModel>.unmodifiable(
      _orderByName<AlbumModel>(index.albums, (a) => a.title,
          descending: descending),
    );
  }

  @override
  Future<List<ArtistModel>> artists({bool descending = false}) async {
    final index = await _ensureIndex();
    return List<ArtistModel>.unmodifiable(
      _orderByName<ArtistModel>(index.artists, (a) => a.name,
          descending: descending),
    );
  }

  @override
  Future<List<GenreModel>> genres({bool descending = false}) async {
    final index = await _ensureIndex();
    return List<GenreModel>.unmodifiable(
      _orderByName<GenreModel>(index.genres, (g) => g.name,
          descending: descending),
    );
  }

  @override
  Future<List<SongModel>> songsInAlbum(int albumId) async {
    final index = await _ensureIndex();
    return _songsByTitle(index, index.songsByAlbum[albumId] ?? const <int>[]);
  }

  @override
  Future<List<SongModel>> songsOfArtist(int artistId) async {
    final index = await _ensureIndex();
    return _songsByTitle(index, index.songsByArtist[artistId] ?? const <int>[]);
  }

  @override
  Future<List<AlbumModel>> albumsOfArtist(int artistId) async {
    final index = await _ensureIndex();
    final ids = index.albumIdsByArtist[artistId] ?? const <int>[];
    final models = <AlbumModel>[
      for (final id in ids)
        if (index.albumById[id] != null) index.albumById[id]!,
    ];
    return List<AlbumModel>.unmodifiable(
      _orderByName<AlbumModel>(models, (a) => a.title),
    );
  }

  @override
  Future<List<SongModel>> songsInGenre(String genreKey) async {
    final index = await _ensureIndex();
    return _songsByTitle(index, index.songsByGenre[genreKey] ?? const <int>[]);
  }

  // ---- Klasörler ----

  @override
  Future<List<FolderModel>> folders({String? parentPath}) async {
    final index = await _ensureIndex();
    final paths = parentPath == null
        ? index.rootFolders
        : (index.childFolders[parentPath] ?? const <String>[]);
    final models = <FolderModel>[
      for (final p in paths) index.folders[p]!,
    ];
    return List<FolderModel>.unmodifiable(
      _orderByName<FolderModel>(models, (f) => f.name),
    );
  }

  @override
  Future<List<SongModel>> songsInFolder(
    String path, {
    bool recursive = false,
  }) async {
    final index = await _ensureIndex();
    if (!recursive) {
      return _songsByTitle(
          index, index.songsByFolder[path] ?? const <int>[]);
    }
    final prefix = '$path/';
    final collected = <int>[];
    index.songsByFolder.forEach((dir, indexes) {
      if (dir == path || dir.startsWith(prefix)) collected.addAll(indexes);
    });
    return _songsByTitle(index, collected);
  }

  // ---- Arama ----

  @override
  Future<LibrarySearchResult> search(
    String query, {
    int limitPerGroup = 100,
  }) async {
    final key = LocaleSorter.searchKey(query.trim());
    final tokens = key
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return LibrarySearchResult.empty;

    final index = await _ensureIndex();
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
      songs: List<SongModel>.unmodifiable(songs),
      albums: List<AlbumModel>.unmodifiable(albums),
      artists: List<ArtistModel>.unmodifiable(artists),
    );
  }

  @override
  Future<Uint8List?> artwork(int songId, {int size = 200}) =>
      _source.queryArtwork(songId, size: size);
}

// ===========================================================================
// İndeks (isolate içinde kurulur; yalnızca gönderilebilir veri tutar)
// ===========================================================================

/// `this` yakalanmasın diye üst düzey işlev.
Future<_LibraryIndex> _buildIndexInIsolate(List<SongModel> songs) =>
    Isolate.run<_LibraryIndex>(() => _buildIndex(songs));

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

  /// MediaStore sırası.
  final List<SongModel> songs;

  /// `songs` ile aynı sıradaki sıralama anahtarları (null: bilinmeyen).
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

  /// Gruplar: şarkı indeksleri (`songs` içindeki konum).
  final Map<int, List<int>> songsByAlbum;
  final Map<int, List<int>> songsByArtist;
  final Map<String, List<int>> songsByGenre;
  final Map<int, List<int>> albumIdsByArtist;

  final Map<String, FolderModel> folders;
  final Map<String, List<int>> songsByFolder;
  final Map<String, List<String>> childFolders;
  final List<String> rootFolders;
}

int _albumIdOf(SongModel s) => (s.album != null && s.albumId != null)
    ? s.albumId!
    : AlbumModel.unknownId;

int _artistIdOf(SongModel s) => (s.artist != null && s.artistId != null)
    ? s.artistId!
    : ArtistModel.unknownId;

final RegExp _volumeRe = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)');

/// `/storage/emulated/0`, `/storage/1234-ABCD`; tanınmazsa ilk yol parçası.
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

/// Ada göre Türkçe sıralar; adı olmayanlar (null) her zaman sonda.
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
  return <T>[for (final e in known) e.$2, ...unknown];
}

_LibraryIndex _buildIndex(List<SongModel> songs) {
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

    // Klasör: doğrudan klasör + depolama köküne kadar tüm üst klasörler.
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

  // Albümler
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
    albumModels.add(
      AlbumModel(
        id: id,
        title: unknown ? null : songs[idxs.first].album,
        artist: _mostFrequent(artistCounts),
        songCount: idxs.length,
        totalDurationMs: duration,
        artworkSongId: unknown ? null : songs[idxs.first].id,
      ),
    );
  });
  final albums = _orderByName<AlbumModel>(albumModels, (a) => a.title);
  final albumById = <int, AlbumModel>{for (final a in albums) a.id: a};
  final albumSearchKeys = <String>[
    for (final a in albums)
      LocaleSorter.searchKey('${a.title ?? ''}\u0001${a.artist ?? ''}'),
  ];

  // Sanatçılar
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
    artistModels.add(
      ArtistModel(
        id: id,
        name: unknown ? null : songs[idxs.first].artist,
        songCount: idxs.length,
        albumCount: albumIds.length,
        totalDurationMs: duration,
        artworkSongId: unknown ? null : songs[idxs.first].id,
      ),
    );
  });
  final artists = _orderByName<ArtistModel>(artistModels, (a) => a.name);
  final artistSearchKeys = <String>[
    for (final a in artists) LocaleSorter.searchKey(a.name ?? ''),
  ];

  // Türler
  final genreModels = <GenreModel>[];
  byGenre.forEach((key, idxs) {
    var duration = 0;
    for (final i in idxs) {
      duration += songs[i].durationMs;
    }
    genreModels.add(
      GenreModel(
        key: key,
        name: genreNames[key],
        songCount: idxs.length,
        totalDurationMs: duration,
        artworkSongId: key.isEmpty ? null : songs[idxs.first].id,
      ),
    );
  });
  final genres = _orderByName<GenreModel>(genreModels, (g) => g.name);

  // Klasörler
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
