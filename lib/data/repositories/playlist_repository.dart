import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';

abstract class PlaylistRepository {
  Future<List<PlaylistModel>> getPlaylists();
  Future<PlaylistModel?> getPlaylist(int id);
  Future<int> createPlaylist(String name);
  Future<void> renamePlaylist(int id, String name);
  Future<void> deletePlaylist(int id);
  
  Future<List<SongModel>> getSongs(int playlistId);
  Future<void> addSong(int playlistId, SongModel song);
  Future<void> removeSong(int playlistId, int songId);
  Future<void> reorderSongs(int playlistId, List<int> songIds);
  Future<bool> isSongInPlaylist(int playlistId, int songId);
}

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._dao, this._libraryRepo);
  final PlaylistDao _dao;
  final LibraryRepository _libraryRepo;

  @override
  Future<List<PlaylistModel>> getPlaylists() async {
    final rows = await _dao.getAll();
    final result = <PlaylistModel>[];
    
    for (final r in rows) {
      final songs = await _dao.getSongsInPlaylist(r.id);
      result.add(PlaylistModel(
        id: r.id,
        name: r.name,
        songCount: songs.length,
        updatedAt: r.updatedAt,
      ));
    }
    return result;
  }

  @override
  Future<PlaylistModel?> getPlaylist(int id) async {
    final r = await _dao.getById(id);
    if (r == null) return null;
    final songs = await _dao.getSongsInPlaylist(id);
    return PlaylistModel(
      id: r.id,
      name: r.name,
      songCount: songs.length,
      updatedAt: r.updatedAt,
    );
  }

  @override
  Future<int> createPlaylist(String name) => _dao.create(name);

  @override
  Future<void> renamePlaylist(int id, String name) => _dao.rename(id, name);

  @override
  Future<void> deletePlaylist(int id) => _dao.deletePlaylist(id);

  @override
  Future<List<SongModel>> getSongs(int playlistId) async {
    final entries = await _dao.getSongsInPlaylist(playlistId);
    final allSongs = await _libraryRepo.songs();
    
    final songMap = {for (var s in allSongs) s.id: s};
    final pathMap = {for (var s in allSongs) s.path: s};
    
    final result = <SongModel>[];
    for (final e in entries) {
      // 1. Önce ID ile ara
      var song = songMap[e.songId];
      // 2. ID yoksa path ile ara (Kural: ID değişirse yeniden bağla)
      if (song == null && e.path != null) {
        song = pathMap[e.path];
      }
      // 3. Bulunursa listeye ekle
      if (song != null) {
        result.add(song);
      }
    }
    return result;
  }

  @override
  Future<void> addSong(int playlistId, SongModel song) => _dao.addSong(playlistId, song);

  @override
  Future<void> removeSong(int playlistId, int songId) => _dao.removeSong(playlistId, songId);

  @override
  Future<void> reorderSongs(int playlistId, List<int> songIds) => _dao.reorderSongs(playlistId, songIds);

  @override
  Future<bool> isSongInPlaylist(int playlistId, int songId) => _dao.isSongInPlaylist(playlistId, songId);
}