import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/banned_song_dao.dart';
import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/data/models/song_model.dart';

/// Gün 17: tek seferde okunan yasak indeksi. Kütüphane indeksi ve oynatıcı
/// koruması O(1) üyelik testi için bu kümeleri kullanır; satır satır DB
/// sorgusu asla yapılmaz (N+1 yok).
class BanIndex {
  const BanIndex({this.ids = const <int>{}, this.paths = const <String>{}});

  final Set<int> ids;
  final Set<String> paths;

  bool get isEmpty => ids.isEmpty && paths.isEmpty;
}

abstract class BannedSongRepository {
  Future<List<BannedSongModel>> getBanned();
  Stream<List<BannedSongModel>> watchBanned();
  Future<void> ban(SongModel song);
  Future<void> unban(BannedSongModel entry);
  Future<BanIndex> banIndex();
}

class BannedSongRepositoryImpl implements BannedSongRepository {
  BannedSongRepositoryImpl(this._dao);

  final BannedSongDao _dao;

  @override
  Future<List<BannedSongModel>> getBanned() async {
    final rows = await _dao.getAll();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<BannedSongModel>> watchBanned() {
    return _dao.watchAll().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<void> ban(SongModel song) => _dao.ban(
        songId: song.id,
        path: song.path,
        title: song.title,
        artist: song.artist,
        album: song.album,
      );

  @override
  Future<void> unban(BannedSongModel entry) => _dao.unbanByPath(entry.path);

  @override
  Future<BanIndex> banIndex() async {
    final rows = await _dao.getAll();
    return BanIndex(
      ids: {for (final r in rows) r.songId},
      paths: {for (final r in rows) r.path},
    );
  }

  BannedSongModel _map(BannedSong r) => BannedSongModel(
        id: r.id,
        songId: r.songId,
        path: r.path,
        title: r.titleSnapshot,
        artist: r.artistSnapshot,
        album: r.albumSnapshot,
        createdAt: r.createdAt,
      );
}
