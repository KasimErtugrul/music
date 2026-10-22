import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';

abstract class FavoriteRepository {
  Stream<List<int>> watchFavoriteIds();
  Future<void> toggleFavorite(int songId);
  Future<bool> isFavorite(int songId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._dao);
  final FavoriteDao _dao;

  @override
  Stream<List<int>> watchFavoriteIds() => _dao.watchAllSongIds();

  @override
  Future<void> toggleFavorite(int songId) async {
    final isFav = await _dao.isFavorite(songId);
    if (isFav) {
      await _dao.remove(songId);
    } else {
      await _dao.add(songId);
    }
  }

  @override
  Future<bool> isFavorite(int songId) => _dao.isFavorite(songId);
}