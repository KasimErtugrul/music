import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/favorites_table.dart';

part 'favorite_dao.g.dart';

@DriftAccessor(tables: [Favorites])
class FavoriteDao extends DatabaseAccessor<AppDatabase>
    with _$FavoriteDaoMixin {
  FavoriteDao(super.db);

  /// `INSERT OR REPLACE`:
  ///  - Aynı `songId` tekrar eklenirse eski satır silinir, yeni satır yeni
  ///    `id` (monotonik AUTOINCREMENT) ile eklenir → liste `id DESC` ile
  ///    sıralandığı için yeniden favorileme şarkıyı **başa taşır**.
  ///  - `insertOnConflictUpdate` KULLANILMAZ: drift bu API'de çakışma
  ///    hedefini PK (`id`) yapar; bizim çakışmamız `songId` unique key'inde
  ///    olduğu için işe yaramaz (UNIQUE constraint failed).
  Future<void> add(int songId) {
    return into(favorites).insert(
      FavoritesCompanion.insert(songId: songId),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> remove(int songId) {
    return (delete(favorites)..where((t) => t.songId.equals(songId))).go();
  }

  Future<bool> isFavorite(int songId) async {
    final row = await (select(favorites)
          ..where((t) => t.songId.equals(songId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// En yeni eklenen önce. `id DESC` timestamp hassasiyetinden bağımsızdır.
  Stream<List<int>> watchAllSongIds() {
    return (select(favorites)..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch()
        .map((rows) => rows.map((r) => r.songId).toList(growable: false));
  }

  Future<List<int>> getAllSongIds() async {
    final rows =
        await (select(favorites)..orderBy([(t) => OrderingTerm.desc(t.id)]))
            .get();
    return rows.map((r) => r.songId).toList(growable: false);
  }
}