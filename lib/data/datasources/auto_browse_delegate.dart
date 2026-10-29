// Aşama 5: Android Auto göz atma ağacı (MediaBrowserService içerik sağlayıcısı).
//
// audio_service 0.18.19, Android Auto'nun MediaBrowserCompat çağrılarını Dart
// tarafındaki ResonanceAudioHandler.getChildren/getMediaItem/search
// override'larına iletir. Bu dosya, handler'ın ince kalması için o
// override'ların TÜM karar mantığını taşır; Flutter bağlamı (context, Get)
// BİLMEDEN çalışır — tüm bağımlılıklar kurucudan enjekte edilir. Böylece
// birim testleri platform kanalları olmadan yazılabilir.
//
// MediaId şeması (Android Auto'da kararlı kimlik sözleşmesi):
//   root                     → kategori listesi (AudioService.rootId = "root")
//   songs                    → tüm şarkılar (oynatılabilir yapraklar)
//   albums                   → album/<id> düğümleri (ızgara stili)
//   album/<id>               → albümün şarkıları
//   artists                  → artist/<id> düğümleri (ızgara stili)
//   artist/<id>              → sanatçının şarkıları
//   genres                   → genre/<kodlu anahtar> düğümleri (ızgara stili)
//   genre/<kodlu anahtar>    → türün şarkıları
//   playlists                → playlist/<id> düğümleri (liste stili)
//   playlist/<id>            → çalma listesinin şarkıları
//   favorites                → favori şarkılar
//   folders                  → depolama kökleri folder/<kodlu yol>
//   folder/<kodlu yol>       → alt klasörler + doğrudan şarkılar
//   song/<id>                → tek şarkı yaprağı
//
// Yol/anahtar kodlama: Uri.encodeComponent; '/' karakteri %2F olur, mediaId
// yol ayracıyla ÇAKIŞMAZ. Çözümlemede Uri.decodeComponent uygulanır.
// Bilinmeyen mediaId'ler asla hata fırlatmaz: boş liste / null / no-op.
import 'package:audio_service/audio_service.dart';
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

/// Android Auto'dan gelen "çal" isteklerini karşılayan minimal arayüz.
/// PlayerController bu sözleşmeyi zaten var olan [PlayerController.playSong]
/// ile karşılar (sınıf bildirimine `implements AutoPlayController` eklendi);
/// ayrı arayüz, delegeyi PlayerController'a (GetX'a) bağımlı olmadan test
/// etmeye yarar.
abstract class AutoPlayController {
  Future<void> playSong(SongModel song, {List<SongModel>? queue});
}

/// Content style ipucu anahtarları (androidx.media.utils.MediaConstants).
/// audio_service 0.18.19, Dart tarafındaki MediaItem.extras'ı
/// MediaDescriptionCompat.setExtras() ile Android Auto'ya iletir
/// (AudioServicePlugin.addExtrasToMediaDescription ile doğrulandı).
abstract class _AutoExtras {
  /// 1 = liste, 2 = ızgara (ContentStyleMediaConstants değerleri).
  static const String browsableHint =
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const String playableHint =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const int styleList = 1;
  static const int styleGrid = 2;

  /// Liste olarak çizilmesi istenen düğüm.
  static const Map<String, dynamic> listNode = <String, dynamic>{
    browsableHint: styleList,
    playableHint: styleList,
  };

  /// Kapaklı kategori (albüm/sanatçı/tür): ızgara olarak çizilsin.
  static const Map<String, dynamic> gridNode = <String, dynamic>{
    browsableHint: styleGrid,
    playableHint: styleList,
  };
}

/// MediaId çözümleyici. Kodlama ve çözümleme tek yerde toplanır; delegenin
/// diğer metodları tip güvenli değerle çalışır.
class AutoMediaId {
  const AutoMediaId.root()
      : kind = AutoMediaIdKind.root,
        id = null,
        token = null;
  const AutoMediaId.unknown()
      : kind = AutoMediaIdKind.unknown,
        id = null,
        token = null;
  const AutoMediaId.category(this.kind)
      : id = null,
        token = null;
  const AutoMediaId.numbered(this.kind, this.id) : token = null;
  const AutoMediaId.labeled(this.kind, this.token) : id = null;

  final String kind;
  final int? id;
  final String? token;

  static AutoMediaId parse(String mediaId) {
    final parts = mediaId.split('/');
    final head = parts.isEmpty ? '' : parts[0];
    switch (head) {
      case AutoMediaIdKind.root:
        return const AutoMediaId.root();
      case AutoMediaIdKind.songs:
      case AutoMediaIdKind.albums:
      case AutoMediaIdKind.artists:
      case AutoMediaIdKind.genres:
      case AutoMediaIdKind.playlists:
      case AutoMediaIdKind.favorites:
      case AutoMediaIdKind.folders:
        return AutoMediaId.category(head);
      case AutoMediaIdKind.album:
      case AutoMediaIdKind.artist:
      case AutoMediaIdKind.playlist:
      case AutoMediaIdKind.song:
        return AutoMediaId.numbered(
            head, int.tryParse(parts.length > 1 ? parts[1] : ''));
      case AutoMediaIdKind.genre:
      case AutoMediaIdKind.folder:
        // Kodlanmış tümce 'genre/' veya 'folder/' önekinden sonrasıdır;
        // decode '%2F' parçalarını tekrar '/' yapar. Önek tek başına gelirse
        // (kurallara aykırı id) boş tümce döner, RangeError oluşmaz.
        final encoded = parts.length > 1 ? mediaId.substring(head.length + 1) : '';
        return AutoMediaId.labeled(head, Uri.decodeComponent(encoded));
      default:
        // Tanınmayan kimlik: hata fırlatma, "unknown" işaretle.
        return const AutoMediaId.unknown();
    }
  }
}

abstract class AutoMediaIdKind {
  static const String root = 'root';
  static const String unknown = 'unknown';
  static const String songs = 'songs';
  static const String albums = 'albums';
  static const String album = 'album';
  static const String artists = 'artists';
  static const String artist = 'artist';
  static const String genres = 'genres';
  static const String genre = 'genre';
  static const String playlists = 'playlists';
  static const String playlist = 'playlist';
  static const String favorites = 'favorites';
  static const String folders = 'folders';
  static const String folder = 'folder';
  static const String song = 'song';
}

class AutoBrowseDelegate {
  AutoBrowseDelegate({
    required LibraryRepository library,
    required PlaylistRepository playlists,
    required FavoriteRepository favorites,
    required AutoPlayController player,
    required AppLocalizations Function() l10n,
    required Future<Uri?> Function(int artworkSongId) artResolver,
  })  : _library = library,
        _playlists = playlists,
        _favorites = favorites,
        _player = player,
        _l10n = l10n,
        _artResolver = artResolver;

  final LibraryRepository _library;
  final PlaylistRepository _playlists;
  final FavoriteRepository _favorites;
  final AutoPlayController _player;
  final AppLocalizations Function() _l10n;
  final Future<Uri?> Function(int artworkSongId) _artResolver;

  /// Kapak çözüm önbelleği (artworkSongId → Uri/null). Android Auto ağaç
  /// taramalarını sık sık tekrarlar; kapak dosyaları temp'te kalıcı
  /// olduğundan ikinci tarama önbellek isabetiyle anlıktır.
  final Map<int, Uri?> _artCache = <int, Uri?>{};

  // --- GÖZ ATMA AĞACI ---------------------------------------------------

  Future<List<MediaItem>> getChildren(String parentMediaId) async {
    final id = AutoMediaId.parse(parentMediaId);
    switch (id.kind) {
      case AutoMediaIdKind.root:
        return _rootChildren();
      case AutoMediaIdKind.songs:
        return _songLeaves(await _library.songs());
      case AutoMediaIdKind.albums:
        return _albumNodes(await _library.albums());
      case AutoMediaIdKind.album:
        return _songLeaves(
            await _library.songsInAlbum(id.id ?? AlbumModel.unknownId));
      case AutoMediaIdKind.artists:
        return _artistNodes(await _library.artists());
      case AutoMediaIdKind.artist:
        return _songLeaves(
            await _library.songsOfArtist(id.id ?? ArtistModel.unknownId));
      case AutoMediaIdKind.genres:
        return _genreNodes(await _library.genres());
      case AutoMediaIdKind.genre:
        return _songLeaves(await _library.songsInGenre(id.token ?? ''));
      case AutoMediaIdKind.playlists:
        return _playlistNodes(await _playlists.getPlaylists());
      case AutoMediaIdKind.playlist:
        return _songLeaves(await _playlists.getSongs(id.id ?? -1));
      case AutoMediaIdKind.favorites:
        return _songLeaves(await favoriteSongs());
      case AutoMediaIdKind.folders:
        return _folderNodes(await _library.folders());
      case AutoMediaIdKind.folder:
        return _folderChildren(id.token ?? '');
      case AutoMediaIdKind.song:
      case AutoMediaIdKind.unknown:
      default:
        // song/<id> bir yapraktır; çocuk sorgusu boş döner (Auto'nun
        // beklediği davranış; hata fırlatmak bağlantıyı düşürür).
        return const <MediaItem>[];
    }
  }

  /// Auto'nun onLoadItem çağrısı: düğümün kendisini döndürür.
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final id = AutoMediaId.parse(mediaId);
    switch (id.kind) {
      case AutoMediaIdKind.song:
        final target = id.id;
        if (target == null) return null;
        SongModel? song;
        for (final s in await _library.songs()) {
          if (s.id == target) {
            song = s;
            break;
          }
        }
        return song == null ? null : _songLeaf(song);
      case AutoMediaIdKind.album:
        AlbumModel? album;
        for (final a in await _library.albums()) {
          if (a.id == id.id) {
            album = a;
            break;
          }
        }
        return album == null ? null : await _albumNode(album);
      case AutoMediaIdKind.artist:
        ArtistModel? artist;
        for (final a in await _library.artists()) {
          if (a.id == id.id) {
            artist = a;
            break;
          }
        }
        return artist == null ? null : await _artistNode(artist);
      case AutoMediaIdKind.genre:
        GenreModel? genre;
        for (final g in await _library.genres()) {
          if (g.key == id.token) {
            genre = g;
            break;
          }
        }
        return genre == null ? null : await _genreNode(genre);
      case AutoMediaIdKind.playlist:
        PlaylistModel? playlist;
        for (final p in await _playlists.getPlaylists()) {
          if (p.id == id.id) {
            playlist = p;
            break;
          }
        }
        return playlist == null ? null : _playlistNode(playlist);
      case AutoMediaIdKind.folder:
        FolderModel? folder;
        // Derin klasör id'leri yalnızca üst klasörün çocuk listesinde bulunur;
        // getMediaItem için kök listesi yeterli değilse null dönmek meşrudur.
        for (final f in await _library.folders(parentPath: null)) {
          if (f.path == id.token) {
            folder = f;
            break;
          }
        }
        return folder == null ? null : _folderNode(folder);
      case AutoMediaIdKind.unknown:
      default:
        return null;
    }
  }

  List<MediaItem> _rootChildren() {
    final l = _l10n();
    // Kök kategorileri liste olarak istenir; ızgara ipuçları kategorilerin
    // İÇİNDEKİ albüm/sanatçı/tür düğümlerine verilir.
    return <MediaItem>[
      MediaItem(
        id: AutoMediaIdKind.songs,
        title: l.autoSongs,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.albums,
        title: l.autoAlbums,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.artists,
        title: l.autoArtists,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.genres,
        title: l.autoGenres,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.playlists,
        title: l.autoPlaylists,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.favorites,
        title: l.autoFavorites,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
      MediaItem(
        id: AutoMediaIdKind.folders,
        title: l.autoFolders,
        playable: false,
        extras: _AutoExtras.listNode,
      ),
    ];
  }

  List<MediaItem> _songLeaves(List<SongModel> songs) => <MediaItem>[
        for (final s in songs) _songLeaf(s),
      ];

  MediaItem _songLeaf(SongModel s) => MediaItem(
        id: '${AutoMediaIdKind.song}/${s.id}',
        title: s.title,
        artist: s.artist,
        album: s.album,
        genre: s.genre,
        duration: s.duration,
        playable: true,
        extras: _AutoExtras.listNode,
      );

  Future<List<MediaItem>> _albumNodes(List<AlbumModel> albums) async =>
      <MediaItem>[
        for (final a in albums) await _albumNode(a),
      ];

  Future<MediaItem> _albumNode(AlbumModel a) async => MediaItem(
        id: '${AutoMediaIdKind.album}/${a.id}',
        title: a.title ?? _l10n().unknownAlbum,
        artist: a.artist,
        album: a.title,
        duration: a.totalDuration,
        artUri: await _artUri(a.artworkSongId),
        playable: false,
        extras: _AutoExtras.gridNode,
      );

  Future<List<MediaItem>> _artistNodes(List<ArtistModel> artists) async =>
      <MediaItem>[
        for (final a in artists) await _artistNode(a),
      ];

  Future<MediaItem> _artistNode(ArtistModel a) async => MediaItem(
        id: '${AutoMediaIdKind.artist}/${a.id}',
        title: a.name ?? _l10n().unknownArtist,
        artist: a.name,
        duration: a.totalDuration,
        artUri: await _artUri(a.artworkSongId),
        playable: false,
        extras: _AutoExtras.gridNode,
      );

  Future<List<MediaItem>> _genreNodes(List<GenreModel> genres) async =>
      <MediaItem>[
        for (final g in genres) await _genreNode(g),
      ];

  Future<MediaItem> _genreNode(GenreModel g) async => MediaItem(
        id: '${AutoMediaIdKind.genre}/${Uri.encodeComponent(g.key)}',
        title: g.name ?? _l10n().unknownGenre,
        genre: g.name,
        duration: g.totalDuration,
        artUri: await _artUri(g.artworkSongId),
        playable: false,
        extras: _AutoExtras.gridNode,
      );

  List<MediaItem> _playlistNodes(List<PlaylistModel> playlists) => <MediaItem>[
        for (final p in playlists) _playlistNode(p),
      ];

  MediaItem _playlistNode(PlaylistModel p) => MediaItem(
        id: '${AutoMediaIdKind.playlist}/${p.id}',
        title: p.name,
        playable: false,
        extras: _AutoExtras.listNode,
      );

  List<MediaItem> _folderNodes(List<FolderModel> folders) => <MediaItem>[
        for (final f in folders) _folderNode(f),
      ];

  MediaItem _folderNode(FolderModel f) => MediaItem(
        id: '${AutoMediaIdKind.folder}/${Uri.encodeComponent(f.path)}',
        // Not: depolama köklerinin ham adı ('0', '1234-ABCD') gösterilir;
        // yerelleştirilmiş kök adı klasörler sayfasına özgü UI metnidir.
        title: f.name,
        playable: false,
        extras: _AutoExtras.listNode,
      );

  Future<List<MediaItem>> _folderChildren(String path) async {
    final subfolders =
        _folderNodes(await _library.folders(parentPath: path));
    final songs = _songLeaves(await _library.songsInFolder(path));
    return <MediaItem>[...subfolders, ...songs];
  }

  // --- ARAMA ------------------------------------------------------------

  /// Android Auto ses araması: LibraryRepository.search üzerinden; şarkı
  /// eşleşmeleri oynatılabilir yapraklara çevrilir.
  Future<List<MediaItem>> search(String query) async {
    final result = await _library.search(query);
    return _songLeaves(result.songs);
  }

  // --- ÇALMA ------------------------------------------------------------

  /// Browsable bir düğüme "çal" emri geldiğinde düğümün şarkı listesi
  /// çözülür ve oynatıcıya devredilir. song/<id> tek şarkıyı çalar
  /// (kuyruk = kendisi); kategori düğümleri ve bilinmeyen id'ler no-op'tur.
  /// Boş çözüm asla oynatma başlatmaz.
  Future<void> playFromMediaId(String mediaId) async {
    final id = AutoMediaId.parse(mediaId);
    final List<SongModel> songs;
    switch (id.kind) {
      case AutoMediaIdKind.song:
        final target = id.id;
        if (target == null) return;
        songs = [
          for (final s in await _library.songs())
            if (s.id == target) s,
        ];
        break;
      case AutoMediaIdKind.songs:
        songs = await _library.songs();
        break;
      case AutoMediaIdKind.album:
        songs = await _library.songsInAlbum(id.id ?? AlbumModel.unknownId);
        break;
      case AutoMediaIdKind.artist:
        songs = await _library.songsOfArtist(id.id ?? ArtistModel.unknownId);
        break;
      case AutoMediaIdKind.genre:
        songs = await _library.songsInGenre(id.token ?? '');
        break;
      case AutoMediaIdKind.playlist:
        songs = await _playlists.getSongs(id.id ?? -1);
        break;
      case AutoMediaIdKind.favorites:
        songs = await favoriteSongs();
        break;
      case AutoMediaIdKind.folder:
        songs = await _library.songsInFolder(id.token ?? '', recursive: true);
        break;
      case AutoMediaIdKind.unknown:
      default:
        return; // albums/artists/... kategorileri çalınamaz
    }
    if (songs.isEmpty) return;
    await _player.playSong(songs.first, queue: songs);
  }

  /// Ses araması: "Tamam Google, Resonance'da X çal" → en iyi eşleşme ilk
  /// şarkı olarak başlar, eşleşen şarkılar kuyruğa alınır.
  Future<void> playFromSearch(String query) async {
    final result = await _library.search(query);
    if (result.songs.isEmpty) return;
    await _player.playSong(result.songs.first, queue: result.songs);
  }

  /// Favori şarkılar: favori id kümesi ile kütüphane sırasının kesişimi.
  /// FavoriteRepository id listesi döndürür (SongModel değil); kütüphane
  /// sırası korunarak filtrelenir.
  Future<List<SongModel>> favoriteSongs() async {
    final ids = (await _favorites.watchFavoriteIds().first).toSet();
    if (ids.isEmpty) return const <SongModel>[];
    final all = await _library.songs();
    return <SongModel>[for (final s in all) if (ids.contains(s.id)) s];
  }

  Future<Uri?> _artUri(int? artworkSongId) async {
    if (artworkSongId == null) return null;
    if (_artCache.containsKey(artworkSongId)) return _artCache[artworkSongId];
    Uri? uri;
    try {
      uri = await _artResolver(artworkSongId);
    } catch (_) {
      uri = null; // Kapak okunamazsa düğüm yine listelenir.
    }
    _artCache[artworkSongId] = uri;
    return uri;
  }
}
