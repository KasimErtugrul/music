import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/auto_browse_delegate.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}
class _MockPlaylistRepository extends Mock implements PlaylistRepository {}
class _MockFavoriteRepository extends Mock implements FavoriteRepository {}

/// playSong çağrılarını kaydeden sahte oynatıcı (AutoPlayController sözleşmesi).
class _FakeAutoPlayer implements AutoPlayController {
  final plays = <({SongModel song, List<SongModel>? queue})>[];

  @override
  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    plays.add((song: song, queue: queue));
  }
}

SongModel _song(int id,
    {String title = 'T',
    String? artist,
    String? album,
    String? genre,
    int? albumId,
    int? artistId}) {
  return SongModel(
    id: id,
    uri: 'content://media/external/audio/media/$id',
    path: '/m/$id.flac',
    title: title,
    durationMs: 60000,
    sizeBytes: 1000,
    artist: artist,
    album: album,
    genre: genre,
    albumId: albumId,
    artistId: artistId,
  );
}

/// Aşama 5: Android Auto göz atma delegesi birim testleri.
/// Tüm bağımlılıklar mocktail ile enjekte edilir; platform kanalı YOKTUR.
void main() {
  late _MockLibraryRepository lib;
  late _MockPlaylistRepository pl;
  late _MockFavoriteRepository fav;
  late _FakeAutoPlayer player;
  late AutoBrowseDelegate delegate;

  setUpAll(() {
    registerFallbackValue(0);
    registerFallbackValue('');
    registerFallbackValue(false);
    registerFallbackValue(_song(1, title: 'Fallback'));
  });

  setUp(() {
    lib = _MockLibraryRepository();
    pl = _MockPlaylistRepository();
    fav = _MockFavoriteRepository();
    player = _FakeAutoPlayer();

    // Varsayılan boş kütüphane; her test kendi verisini ezer.
    when(() => lib.songs()).thenAnswer((_) async => <SongModel>[]);
    when(() => lib.albums()).thenAnswer((_) async => <AlbumModel>[]);
    when(() => lib.artists()).thenAnswer((_) async => <ArtistModel>[]);
    when(() => lib.genres()).thenAnswer((_) async => <GenreModel>[]);
    when(() => lib.folders()).thenAnswer((_) async => <FolderModel>[]);
    when(() => lib.folders(parentPath: any(named: 'parentPath')))
        .thenAnswer((_) async => <FolderModel>[]);
    when(() => lib.songsInAlbum(any())).thenAnswer((_) async => <SongModel>[]);
    when(() => lib.songsOfArtist(any())).thenAnswer((_) async => <SongModel>[]);
    when(() => lib.songsInGenre(any())).thenAnswer((_) async => <SongModel>[]);
    when(() => lib.songsInFolder(any(), recursive: any(named: 'recursive')))
        .thenAnswer((_) async => <SongModel>[]);
    when(() => lib.search(any()))
        .thenAnswer((_) async => LibrarySearchResult.empty);
    when(() => lib.artwork(any(), size: any(named: 'size')))
        .thenAnswer((_) async => null);
    when(() => pl.getPlaylists()).thenAnswer((_) async => <PlaylistModel>[]);
    when(() => pl.getSongs(any())).thenAnswer((_) async => <SongModel>[]);
    when(() => fav.watchFavoriteIds())
        .thenAnswer((_) => Stream.value(<int>[]));

    delegate = AutoBrowseDelegate(
      library: lib,
      playlists: pl,
      favorites: fav,
      player: player,
      l10n: () => lookupAppLocalizations(const Locale('en')),
      artResolver: (id) async => Uri.file('/art/$id.jpg'),
    );
  });

  group('kök kategoriler', () {
    test('kök: 7 kategori, sıra ve İngilizce etiketler doğru', () async {
      final children = await delegate.getChildren('root');
      expect(children.map((e) => e.id).toList(),
          ['songs', 'albums', 'artists', 'genres', 'playlists', 'favorites', 'folders']);
      expect(children.map((e) => e.title).toList(), [
        'Songs', 'Albums', 'Artists', 'Genres', 'Playlists', 'Favorites', 'Folders'
      ]);
      // Kök düğümler browsable olmalı (playable: false → FLAG_BROWSABLE).
      expect(children.every((e) => e.playable == false), isTrue);
      // Kök kategorileri liste stili ipucu taşır (1 = liste).
      expect(
        children.every((e) =>
            e.extras?['android.media.browse.CONTENT_STYLE_BROWSABLE_HINT'] == 1),
        isTrue,
      );
    });

    test('kök: Türkçe etiketler lookupAppLocalizations ile gelir', () async {
      final trDelegate = AutoBrowseDelegate(
        library: lib,
        playlists: pl,
        favorites: fav,
        player: player,
        l10n: () => lookupAppLocalizations(const Locale('tr')),
        artResolver: (id) async => null,
      );
      final children = await trDelegate.getChildren('root');
      expect(children.map((e) => e.title).toList(), [
        'Şarkılar', 'Albümler', 'Sanatçılar', 'Türler',
        'Çalma Listeleri', 'Favoriler', 'Klasörler',
      ]);
    });

    test('boş kütüphanede de kök 7 kategori döner', () async {
      final children = await delegate.getChildren('root');
      expect(children, hasLength(7));
    });
  });

  group('bilinmeyen / yaprak mediaId güvenliği', () {
    test('bilinmeyen id: boş çocuk + null öğe + no-op çalma', () async {
      expect(await delegate.getChildren('garbage/xyz'), isEmpty);
      expect(await delegate.getMediaItem('garbage/xyz'), isNull);
      await delegate.playFromMediaId('garbage/xyz');
      expect(player.plays, isEmpty);
    });

    test('song/<id> yaprağı çocuk sorgusunda boş döner', () async {
      expect(await delegate.getChildren('song/7'), isEmpty);
    });
  });

  group('şarkılar', () {
    test('songs: tüm şarkılar oynatılabilir yapraklara çevrilir', () async {
      when(() => lib.songs()).thenAnswer((_) async =>
          [_song(1, title: 'A', artist: 'X', album: 'L'), _song(2, title: 'B')]);
      final children = await delegate.getChildren('songs');
      expect(children, hasLength(2));
      expect(children[0].id, 'song/1');
      expect(children[0].title, 'A');
      expect(children[0].artist, 'X');
      expect(children[0].album, 'L');
      expect(children[0].duration, const Duration(seconds: 60));
      expect(children[0].playable, isTrue);
      expect(children[1].id, 'song/2');
      expect(children[1].playable, isTrue);
    });
  });

  group('albümler', () {
    test('albums: ızgara ipucu, kapak Uri ve bilinmeyen albüm etiketi',
        () async {
      when(() => lib.albums()).thenAnswer((_) async => [
            const AlbumModel(
                id: 3,
                songCount: 2,
                totalDurationMs: 120000,
                title: 'Night Drive',
                artist: 'Y',
                artworkSongId: 9),
            const AlbumModel(id: AlbumModel.unknownId, songCount: 1, totalDurationMs: 1),
          ]);
      final children = await delegate.getChildren('albums');
      expect(children[0].id, 'album/3');
      expect(children[0].title, 'Night Drive');
      expect(children[0].artist, 'Y');
      expect(children[0].artUri, Uri.file('/art/9.jpg'));
      expect(
        children[0].extras?['android.media.browse.CONTENT_STYLE_BROWSABLE_HINT'],
        2,
      );
      expect(children[1].title, 'Unknown album');
      expect(children[1].artUri, isNull);
    });

    test('album/<id>: albümün şarkıları oynatılabilir döner', () async {
      when(() => lib.songsInAlbum(3))
          .thenAnswer((_) async => [_song(11), _song(12)]);
      final children = await delegate.getChildren('album/3');
      expect(children.map((e) => e.id).toList(), ['song/11', 'song/12']);
      expect(children.every((e) => e.playable == true), isTrue);
    });

    test('playFromMediaId album/<id>: tüm albüm kuyruğa girer', () async {
      when(() => lib.songsInAlbum(3))
          .thenAnswer((_) async => [_song(11), _song(12)]);
      await delegate.playFromMediaId('album/3');
      expect(player.plays, hasLength(1));
      expect(player.plays.single.song.id, 11);
      expect(player.plays.single.queue, hasLength(2));
    });

    test('kapak çözümü önbelleğe alınır (ikinci tarama çözücüye uğramaz)',
        () async {
      var resolverCalls = 0;
      when(() => lib.albums()).thenAnswer((_) async => [
            const AlbumModel(id: 3, songCount: 1, totalDurationMs: 1, artworkSongId: 9),
          ]);
      final cached = AutoBrowseDelegate(
        library: lib,
        playlists: pl,
        favorites: fav,
        player: player,
        l10n: () => lookupAppLocalizations(const Locale('en')),
        artResolver: (id) async {
          resolverCalls += 1;
          return Uri.file('/art/$id.jpg');
        },
      );
      await cached.getChildren('albums');
      await cached.getChildren('albums');
      expect(resolverCalls, 1);
    });
  });

  group('sanatçılar', () {
    test('artist/<id>: sanatçının şarkıları ve tam albüm çalma', () async {
      when(() => lib.artists()).thenAnswer((_) async => [
            const ArtistModel(
                id: 4, songCount: 2, albumCount: 1, totalDurationMs: 2, name: 'Z'),
            const ArtistModel(id: ArtistModel.unknownId, songCount: 1, albumCount: 0, totalDurationMs: 1),
          ]);
      final nodes = await delegate.getChildren('artists');
      expect(nodes[0].id, 'artist/4');
      expect(nodes[0].title, 'Z');
      expect(nodes[1].title, 'Unknown artist');

      when(() => lib.songsOfArtist(4))
          .thenAnswer((_) async => [_song(21), _song(22)]);
      final songs = await delegate.getChildren('artist/4');
      expect(songs.map((e) => e.id).toList(), ['song/21', 'song/22']);

      await delegate.playFromMediaId('artist/4');
      expect(player.plays.single.song.id, 21);
      expect(player.plays.single.queue, hasLength(2));
    });
  });

  group('türler', () {
    test('genre/<kodlu anahtar>: boşluk ve eğik çizgi kodlaması sağlam',
        () async {
      when(() => lib.genres()).thenAnswer((_) async => [
            const GenreModel(
                key: 'hip hop/rap',
                name: 'Hip Hop/Rap',
                songCount: 2,
                totalDurationMs: 2),
          ]);
      final nodes = await delegate.getChildren('genres');
      expect(nodes.single.id, 'genre/hip%20hop%2Frap');

      // Auto, düğümün id'sini aynen geri gönderir; roundtrip aynı anahtara çözülmeli.
      when(() => lib.songsInGenre('hip hop/rap'))
          .thenAnswer((_) async => [_song(31, genre: 'Hip Hop/Rap')]);
      final songs = await delegate.getChildren('genre/hip%20hop%2Frap');
      expect(songs, hasLength(1));
      expect(songs.single.id, 'song/31');
    });
  });

  group('çalma listeleri', () {
    test('playlist/<id>: çocuklar ve düğümden çalma', () async {
      when(() => pl.getPlaylists()).thenAnswer((_) async => [
            PlaylistModel(
                id: 5,
                name: 'Drive',
                songCount: 2,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0)),
          ]);
      final nodes = await delegate.getChildren('playlists');
      expect(nodes.single.id, 'playlist/5');
      expect(nodes.single.title, 'Drive');
      expect(nodes.single.playable, isFalse);

      when(() => pl.getSongs(5)).thenAnswer((_) async => [_song(41), _song(42)]);
      final songs = await delegate.getChildren('playlist/5');
      expect(songs.map((e) => e.id).toList(), ['song/41', 'song/42']);

      await delegate.playFromMediaId('playlist/5');
      expect(player.plays.single.song.id, 41);
      expect(player.plays.single.queue, hasLength(2));
    });
  });

  group('favoriler', () {
    test('favorites: id kümesiyle filtreleme, kütüphane sırası korunur',
        () async {
      when(() => fav.watchFavoriteIds()).thenAnswer((_) => Stream.value([30, 10]));
      when(() => lib.songs()).thenAnswer(
          (_) async => [_song(10, title: 'A'), _song(20, title: 'B'), _song(30, title: 'C')]);

      final children = await delegate.getChildren('favorites');
      expect(children.map((e) => e.id).toList(), ['song/10', 'song/30']);

      await delegate.playFromMediaId('favorites');
      expect(player.plays.single.song.id, 10);
      expect(player.plays.single.queue!.map((s) => s.id).toList(), [10, 30]);
    });

    test('favorites: favori yoksa boş döner ve çalma tetiklenmez', () async {
      when(() => fav.watchFavoriteIds()).thenAnswer((_) => Stream.value(<int>[]));
      expect(await delegate.getChildren('favorites'), isEmpty);
      await delegate.playFromMediaId('favorites');
      expect(player.plays, isEmpty);
    });
  });

  group('klasörler', () {
    const musicPath = '/storage/emulated/0/Music';
    const musicId = 'folder/%2Fstorage%2Femulated%2F0%2FMusic';

    test('folders: depolama kökleri kodlanmış id taşır', () async {
      when(() => lib.folders()).thenAnswer((_) async => [
            const FolderModel(
                path: musicPath,
                name: 'Music',
                songCount: 5,
                directSongCount: 5,
                totalDurationMs: 1,
                isVolumeRoot: true),
          ]);
      final nodes = await delegate.getChildren('folders');
      expect(nodes.single.id, musicId);
      expect(nodes.single.title, 'Music');
    });

    test('folder/<yol>: alt klasörler + doğrudan şarkılar', () async {
      when(() => lib.folders(parentPath: musicPath)).thenAnswer((_) async => [
            const FolderModel(
                path: '$musicPath/Rock',
                name: 'Rock',
                songCount: 2,
                directSongCount: 2,
                totalDurationMs: 1,
                isVolumeRoot: false,
                parentPath: musicPath),
          ]);
      when(() => lib.songsInFolder(musicPath))
          .thenAnswer((_) async => [_song(51)]);

      final children = await delegate.getChildren(musicId);
      expect(children, hasLength(2));
      expect(
        children[0].id,
        'folder/%2Fstorage%2Femulated%2F0%2FMusic%2FRock',
      );
      expect(children[1].id, 'song/51');
      expect(children[1].playable, isTrue);
    });

    test('playFromMediaId folder/<yol>: klasör KENDİSİ özyinelemeli çalınır',
        () async {
      when(() => lib.songsInFolder(musicPath, recursive: true))
          .thenAnswer((_) async => [_song(51), _song(52)]);
      await delegate.playFromMediaId(musicId);
      expect(player.plays.single.song.id, 51);
      expect(player.plays.single.queue, hasLength(2));
    });
  });

  group('arama', () {
    test('search: şarkı eşleşmeleri oynatılabilir yaprak döner', () async {
      when(() => lib.search('love')).thenAnswer((_) async =>
          LibrarySearchResult(songs: [_song(61), _song(62)]));
      final results = await delegate.search('love');
      expect(results, hasLength(2));
      expect(results.every((e) => e.playable == true), isTrue);
    });

    test('playFromSearch: ilk eşleşme başlar, eşleşenler kuyruğa girer',
        () async {
      when(() => lib.search('love')).thenAnswer((_) async =>
          LibrarySearchResult(songs: [_song(61), _song(62)]));
      await delegate.playFromSearch('love');
      expect(player.plays.single.song.id, 61);
      expect(player.plays.single.queue, hasLength(2));
    });

    test('playFromSearch: sonuç yoksa oynatma tetiklenmez', () async {
      await delegate.playFromSearch('nothing-matches');
      expect(player.plays, isEmpty);
    });
  });

  group('getMediaItem', () {
    test('song/<id>: şarkı öğesi döner; olmayan id null', () async {
      when(() => lib.songs())
          .thenAnswer((_) async => [_song(7, title: 'Seven', artist: 'A7')]);
      final item = await delegate.getMediaItem('song/7');
      expect(item, isNotNull);
      expect(item!.title, 'Seven');
      expect(item.artist, 'A7');
      expect(item.playable, isTrue);
      expect(await delegate.getMediaItem('song/99'), isNull);
    });

    test('album/<id> ve playlist/<id>: düğüm kendisi döner', () async {
      when(() => lib.albums()).thenAnswer((_) async => [
            const AlbumModel(id: 3, songCount: 1, totalDurationMs: 1, title: 'X'),
          ]);
      when(() => pl.getPlaylists()).thenAnswer((_) async => [
            PlaylistModel(
                id: 5,
                name: 'Drive',
                songCount: 1,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0)),
          ]);
      expect((await delegate.getMediaItem('album/3'))!.title, 'X');
      expect((await delegate.getMediaItem('playlist/5'))!.title, 'Drive');
    });
  });
}
