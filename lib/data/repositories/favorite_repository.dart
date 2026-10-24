import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';
import 'package:resonance/data/models/song_model.dart';

abstract class FavoriteRepository {
  Stream<List<int>> watchFavoriteIds();
  Future<void> toggleFavorite(SongModel song);
  Future<bool> isFavorite(int songId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._dao);
  final FavoriteDao _dao;

  @override
  Stream<List<int>> watchFavoriteIds() => _dao.watchAllSongIds();

  @override
  Future<void> toggleFavorite(SongModel song) async {
    final isFav = await _dao.isFavorite(song.id);
    if (isFav) {
      await _dao.remove(song.id);
    } else {
      await _dao.add(song);
    }
  }

  @override
  Future<bool> isFavorite(int songId) => _dao.isFavorite(songId);
}