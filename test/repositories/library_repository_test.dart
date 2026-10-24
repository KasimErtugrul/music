import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/errors/app_exception.dart';
import 'package:resonance/core/utils/locale_sorter.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';

class FakeDataSource implements DeviceMediaDataSource {
  FakeDataSource(this.songs);

  List<SongModel> songs;
  Object? error;
  int queryCount = 0;

  @override
  String get name => 'fake';

  @override
  Future<List<SongModel>> querySongs() async {
    queryCount++;
    final e = error;
    if (e != null) throw e;
    return songs;
  }

  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 200}) async => null;
}

/// Testler için varsayılan ayarlarla dönen basit sahte PreferencesRepository.
/// `minDurationSeconds = 0` → filtreleme yapmaz, tüm şarkılar geçer.
class _FakePreferencesRepository implements PreferencesRepository {
 
 
  @override
  Future<LibrarySettingsModel> loadLibrary() async =>
      const LibrarySettingsModel();

  @override
  Future<PlaybackSettingsModel> loadPlayback() async =>
      const PlaybackSettingsModel();

  @override
  Future<void> resetAll() async {}

  @override
  Future<void> saveLibrary(LibrarySettingsModel settings) async {}

  @override
  Future<void> savePlayback(PlaybackSettingsModel settings) async {}
}

class _FakeExcludedFolderRepository implements ExcludedFolderRepository {
  @override
  Future<List<ExcludedFolderModel>> getExcludedFolders() async => [];

  @override
  Future<void> addFolder(String path) async {}

  @override
  Future<void> removeFolder(String path) async {}
}

SongModel song(
  int id,
  String title, {
  String? artist,
  String? album,
  String? genre,
  int? albumId,
  int? artistId,
  int durationMs = 180000,
  DateTime? dateAdded,
  String? path,
}) =>
    SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: path ?? '/storage/emulated/0/Music/$id.mp3',
      title: title,
      durationMs: durationMs,
      sizeBytes: 1000,
      artist: artist,
      album: album,
      genre: genre,
      albumId: albumId,
      artistId: artistId,
      dateAdded: dateAdded,
    );

/// Altı şarkılık temel veri.
List<SongModel> fixture() => <SongModel>[
      song(1, 'Zeybek',
          artist: 'Ege', album: 'Kıyı', albumId: 10, artistId: 100,
          genre: 'pop', durationMs: 200000, dateAdded: DateTime(2026, 1, 3)),
      song(2, 'Çiçek',
          artist: 'Ayşe', album: 'Bahar', albumId: 11, artistId: 101,
          genre: 'Rock', durationMs: 100000, dateAdded: DateTime(2026, 1, 1)),
      song(3, 'Ankara',
          artist: 'Ege', album: 'Kıyı', albumId: 10, artistId: 100,
          genre: 'Rock', durationMs: 300000, dateAdded: DateTime(2026, 1, 2)),
      song(4, 'ılık', durationMs: 50000),
      song(5, 'Intro',
          artist: 'Ayşe', album: 'Bahar', albumId: 11, artistId: 101,
          genre: 'Pop', durationMs: 150000, dateAdded: DateTime(2026, 1, 4)),
      song(6, 'Şarkı',
          artist: 'Ege', albumId: 12, artistId: 100,
          durationMs: 120000, dateAdded: DateTime(2026, 1, 5)),
    ];

List<int> ids(List<SongModel> list) => list.map((s) => s.id).toList();

void main() {
  late FakeDataSource source;
  late LibraryRepositoryImpl repo;

  setUp(() {
    source = FakeDataSource(fixture());
     repo = LibraryRepositoryImpl(
      source,
      _FakePreferencesRepository(),
      _FakeExcludedFolderRepository(), // ← EKLENDİ
      useIsolate: false,
    );
  });

  group('şarkı sıralaması', () {
    test('ad: Türkçe sıra (ç, ı, ş doğru yerde)', () async {
      final list = await repo.songs();
      expect(ids(list), <int>[3, 2, 4, 5, 6, 1]);
    });

    test('ad azalan', () async {
      final list = await repo
          .songs(sort: const SongSort(direction: SortDirection.descending));
      expect(ids(list), <int>[1, 6, 5, 4, 2, 3]);
    });

    test('sanatçı artan: bilinmeyen sonda, eşitlikte albüm sonra ad', () async {
      final list = await repo.songs(
        sort: const SongSort(field: SongSortField.artist),
      );
      expect(ids(list), <int>[2, 5, 3, 1, 6, 4]);
    });

    test('sanatçı azalan: bilinmeyen yine sonda', () async {
      final list = await repo.songs(
        sort: const SongSort(
          field: SongSortField.artist,
          direction: SortDirection.descending,
        ),
      );
      expect(ids(list), <int>[3, 1, 6, 2, 5, 4]);
    });

    test('süre azalan', () async {
      final list = await repo.songs(
        sort: const SongSort(
          field: SongSortField.duration,
          direction: SortDirection.descending,
        ),
      );
      expect(ids(list), <int>[3, 1, 5, 6, 2, 4]);
    });

    test('tarih: tarihsiz en eski sayılır', () async {
      final asc = await repo.songs(
        sort: const SongSort(field: SongSortField.dateAdded),
      );
      expect(ids(asc), <int>[4, 2, 3, 1, 5, 6]);
      final desc = await repo.songs(
        sort: const SongSort(
          field: SongSortField.dateAdded,
          direction: SortDirection.descending,
        ),
      );
      expect(ids(desc), <int>[6, 5, 1, 3, 2, 4]);
    });

    test('sonuç değiştirilemez ve önbellekten gelir', () async {
      final a = await repo.songs();
      final b = await repo.songs();
      expect(identical(a, b), isTrue);
      expect(() => a.add(a.first), throwsUnsupportedError);
    });
  });

  group('A–Z indeksi', () {
    test('ad sıralaması: harf → ilk konum', () async {
      final offsets = await repo.letterOffsets(const SongSort());
      expect(offsets,
          <String, int>{'A': 0, 'Ç': 1, 'I': 2, 'Ş': 4, 'Z': 5});
      expect(offsets.keys.toList(), <String>['A', 'Ç', 'I', 'Ş', 'Z']);
    });

    test('sanatçı sıralaması: bilinmeyen … altında', () async {
      final offsets = await repo.letterOffsets(
        const SongSort(field: SongSortField.artist),
      );
      expect(offsets, <String, int>{'A': 0, 'E': 2, '…': 5});
    });

    test('tarih ve süre sıralamasında boş', () async {
      expect(
        await repo
            .letterOffsets(const SongSort(field: SongSortField.duration)),
        isEmpty,
      );
    });
  });

  group('albümler, sanatçılar, türler', () {
    test('albümler gruplanır; bilinmeyen sonda', () async {
      final albums = await repo.albums();
      expect(albums.map((a) => a.id).toList(),
          <int>[11, 10, AlbumModel.unknownId]);

      final kiyi = albums[1];
      expect(kiyi.title, 'Kıyı');
      expect(kiyi.artist, 'Ege');
      expect(kiyi.songCount, 2);
      expect(kiyi.totalDurationMs, 500000);

      final unknown = albums.last;
      expect(unknown.isUnknown, isTrue);
      expect(unknown.title, isNull);
      expect(unknown.songCount, 2);
      expect(unknown.artworkSongId, isNull);
    });

    test('albümler azalan: bilinmeyen yine sonda', () async {
      final albums = await repo.albums(descending: true);
      expect(albums.map((a) => a.id).toList(),
          <int>[10, 11, AlbumModel.unknownId]);
    });

    test('sanatçılar: şarkı/albüm sayısı, bilinmeyen sonda', () async {
      final artists = await repo.artists();
      expect(artists.map((a) => a.name).toList(),
          <String?>['Ayşe', 'Ege', null]);
      expect(artists[1].songCount, 3);
      expect(artists[1].albumCount, 1);
      expect(artists[0].albumCount, 1);
      expect(artists[2].albumCount, 0);
    });

    test('türler: büyük/küçük yazım birleşir, bilinmeyen sonda', () async {
      final genres = await repo.genres();
      expect(genres.map((g) => g.key).toList(), <String>['pop', 'rock', '']);
      expect(genres[0].name, 'pop');
      expect(genres[0].songCount, 2);
      expect(genres[1].songCount, 2);
      expect(genres[2].songCount, 2);
      expect(genres[2].isUnknown, isTrue);
    });

    test('detay sorguları', () async {
      expect(ids(await repo.songsInAlbum(10)), <int>[3, 1]);
      expect(ids(await repo.songsInAlbum(AlbumModel.unknownId)), <int>[4, 6]);
      expect(ids(await repo.songsOfArtist(100)), <int>[3, 6, 1]);
      expect(ids(await repo.songsInGenre('rock')), <int>[3, 2]);
      expect(ids(await repo.songsInGenre('olmayan')), isEmpty);
      final albumsOfEge = await repo.albumsOfArtist(100);
      expect(albumsOfEge.map((a) => a.id).toList(), <int>[10]);
    });
  });

  group('klasörler', () {
    setUp(() {
      source.songs = <SongModel>[
        song(1, 'Zeybek', path: '/storage/emulated/0/Music/Pop/a.mp3'),
        song(2, 'Çiçek', path: '/storage/emulated/0/Music/Pop/b.mp3'),
        song(3, 'Ankara', path: '/storage/emulated/0/Music/Rock/c.mp3'),
        song(4, 'Dosya', path: '/storage/emulated/0/Download/d.mp3'),
        song(5, 'Kart', path: '/storage/1234-ABCD/Music/e.mp3'),
        song(6, 'Yolsuz', path: ''),
      ];
    });

    test('kökler: depolama birimleri, yolu olmayan şarkı atlanır', () async {
      final roots = await repo.folders();
      expect(roots.map((f) => f.path).toList(), <String>[
        '/storage/emulated/0',
        '/storage/1234-ABCD',
      ]);
      expect(roots.every((f) => f.isVolumeRoot && f.parentPath == null), isTrue);
      expect(roots[0].songCount, 4);
      expect(roots[0].directSongCount, 0);
      expect(roots[1].songCount, 1);
    });

    test('alt klasörler ve sayılar', () async {
      final kids = await repo.folders(parentPath: '/storage/emulated/0');
      expect(kids.map((f) => f.name).toList(), <String>['Download', 'Music']);
      expect(kids[1].songCount, 3);
      expect(kids[1].directSongCount, 0);
      expect(kids[1].parentPath, '/storage/emulated/0');

      final music = await repo.folders(parentPath: '/storage/emulated/0/Music');
      expect(music.map((f) => f.name).toList(), <String>['Pop', 'Rock']);
      expect(music[0].songCount, 2);
      expect(music[0].directSongCount, 2);
      expect(await repo.folders(parentPath: '/yok'), isEmpty);
    });

    test('klasördeki şarkılar: doğrudan ve özyinelemeli', () async {
      expect(
        ids(await repo.songsInFolder('/storage/emulated/0/Music/Pop')),
        <int>[2, 1],
      );
      expect(ids(await repo.songsInFolder('/storage/emulated/0/Music')), isEmpty);
      expect(
        ids(await repo
            .songsInFolder('/storage/emulated/0/Music', recursive: true)),
        <int>[3, 2, 1],
      );
      source.songs = <SongModel>[
        ...source.songs,
        song(7, 'Eski', path: '/storage/emulated/0/MusicOld/x.mp3'),
      ];
      await repo.rescan();
      expect(
        ids(await repo
            .songsInFolder('/storage/emulated/0/Music', recursive: true)),
        <int>[3, 2, 1],
      );
    });
  });

  group('arama', () {
    test('Türkçe harf ve büyük/küçük harf duyarsız', () async {
      final r = await repo.search('sarki');
      expect(ids(r.songs), <int>[6]);
      expect(ids((await repo.search('ŞARKI')).songs), <int>[6]);
      expect(ids((await repo.search('cicek')).songs), <int>[2]);
    });

    test('I / ı / İ / i eşdeğer', () async {
      source.songs = <SongModel>[
        song(1, 'Isparta Güzeli'),
        song(2, 'İzmir Marşı'),
        song(3, 'ışık'),
      ];
      await repo.rescan();
      expect(ids((await repo.search('ISPARTA')).songs), <int>[1]);
      expect(ids((await repo.search('izmir')).songs), <int>[2]);
      expect(ids((await repo.search('ışık')).songs), <int>[3]);
      expect(ids((await repo.search('isik')).songs), <int>[3]);
    });

    test('birden çok kelime: hepsi geçmeli; şarkı/albüm/sanatçıda aranır',
        () async {
      final r = await repo.search('ege kiyi');
      expect(ids(r.songs), <int>[3, 1]);

      final byArtist = await repo.search('ege');
      expect(byArtist.artists.map((a) => a.name).toList(), <String?>['Ege']);
      expect(byArtist.albums.map((a) => a.title).toList(), <String?>['Kıyı']);
      expect(ids(byArtist.songs), <int>[3, 6, 1]);
    });

    test('boş sorgu ve sonuç yok', () async {
      expect((await repo.search('   ')).isEmpty, isTrue);
      expect((await repo.search('yokböyle')).isEmpty, isTrue);
    });

    test('bilinmeyen albüm/sanatçı sonuçlarda görünmez', () async {
      final r = await repo.search('bilinmeyen');
      expect(r.albums, isEmpty);
      expect(r.artists, isEmpty);
    });

    test('limitPerGroup uygulanır', () async {
      expect((await repo.search('e', limitPerGroup: 2)).songs, hasLength(2));
    });
  });

  group('okuma ve yeniden tarama', () {
    test('eşzamanlı çağrılar cihazı bir kez okur', () async {
      await Future.wait<Object>(<Future<Object>>[
        repo.songs(),
        repo.albums(),
        repo.artists(),
        repo.genres(),
        repo.folders(),
      ]);
      expect(source.queryCount, 1);
      await repo.songs();
      expect(source.queryCount, 1);
    });

    test('rescan yeni veriyi okur ve önbelleği atar', () async {
      expect(await repo.songs(), hasLength(6));
      source.songs = <SongModel>[song(99, 'Yeni')];
      await repo.rescan();
      expect(source.queryCount, 2);
      expect(ids(await repo.songs()), <int>[99]);
      expect((await repo.albums()).single.isUnknown, isTrue);
    });

    test('hata AppException olarak yükselir ve sonraki çağrı yeniden dener',
        () async {
      source.error = const AppException(AppErrorCode.mediaQueryFailed);
      await expectLater(repo.songs(), throwsA(isA<AppException>()));
      source.error = null;
      expect(await repo.songs(), hasLength(6));
    });

    test('boş kütüphane', () async {
      source.songs = <SongModel>[];
      expect(await repo.songs(), isEmpty);
      expect(await repo.albums(), isEmpty);
      expect(await repo.folders(), isEmpty);
      expect(await repo.letterOffsets(const SongSort()), isEmpty);
    });

    test('kapak datasource\'a iletilir', () async {
      expect(await repo.artwork(1), isNull);
    });
  });

  group('10.000 şarkı', () {
    List<SongModel> bigLibrary(int n) {
      final rnd = Random(42);
      const words = <String>[
        'Aşk', 'Gece', 'Ömür', 'Işık', 'Deniz', 'Yağmur', 'Şehir', 'Ülke',
        'Çocuk', 'Rüzgar', 'Love', 'Night', 'Dream', 'Road', 'Fire', 'Sky',
      ];
      const genres = <String>['Pop', 'Rock', 'Jazz', 'Arabesk', 'Türk Halk'];
      return <SongModel>[
        for (var i = 0; i < n; i++)
          () {
            final artistNo = rnd.nextInt(400);
            final albumNo = rnd.nextInt(1500);
            return song(
              i + 1,
              '${words[rnd.nextInt(words.length)]} '
              '${words[rnd.nextInt(words.length)]} $i',
              artist: 'Sanatçı $artistNo',
              artistId: 1000 + artistNo,
              album: 'Albüm $albumNo',
              albumId: 1 + albumNo,
              genre: genres[rnd.nextInt(genres.length)],
              durationMs: 60000 + rnd.nextInt(300000),
              dateAdded: DateTime(2020)
                  .add(Duration(hours: rnd.nextInt(50000))),
              path: '/storage/emulated/0/Music/k${rnd.nextInt(200)}/$i.mp3',
            );
          }(),
      ];
    }

    test('isolate ile indeks kurulur; sorgular tutarlı ve hızlı', () async {
      final big = LibraryRepositoryImpl(
        FakeDataSource(bigLibrary(10000)),
        _FakePreferencesRepository(),
        _FakeExcludedFolderRepository(), // ← EKLENDİ
      );
      final watch = Stopwatch()..start();

      final byTitle = await big.songs();
      expect(byTitle, hasLength(10000));
      for (var i = 0; i < byTitle.length - 1; i += 7) {
        expect(
          LocaleSorter.compare(byTitle[i].title, byTitle[i + 1].title),
          lessThanOrEqualTo(0),
          reason: 'sıra bozuk: ${byTitle[i].title} / ${byTitle[i + 1].title}',
        );
      }
      for (final field in SongSortField.values) {
        expect(
          await big.songs(sort: SongSort(field: field)),
          hasLength(10000),
        );
      }

      final albums = await big.albums();
      expect(albums.fold<int>(0, (sum, a) => sum + a.songCount), 10000);
      final artists = await big.artists();
      expect(artists.fold<int>(0, (sum, a) => sum + a.songCount), 10000);
      expect(artists.length, lessThanOrEqualTo(400));

      final roots = await big.folders();
      expect(roots, hasLength(1));
      expect(roots.single.songCount, 10000);

      final found = await big.search('gece ask');
      expect(found.songs, isNotEmpty);
      for (final s in found.songs) {
        final key =
            LocaleSorter.searchKey('${s.title} ${s.artist} ${s.album}');
        expect(key, allOf(contains('gece'), contains('ask')));
      }

      watch.stop();
      debugPrint('10.000 şarkı: toplam ${watch.elapsedMilliseconds} ms');
      expect(watch.elapsedMilliseconds, lessThan(5000));
    });
  });
}