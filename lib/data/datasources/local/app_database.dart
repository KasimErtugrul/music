import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/datasources/local/tables/favorites_table.dart';
import 'package:resonance/data/datasources/local/tables/lyrics_table.dart';
import 'package:resonance/data/datasources/local/tables/play_history_table.dart';
import 'package:resonance/data/datasources/local/tables/playlist_songs_table.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Playlists, PlaylistSongs, Favorites, PlayHistory, Lyrics],
  daos: [PlaylistDao, FavoriteDao, HistoryDao, LyricsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Testlerde `AppDatabase(NativeDatabase.memory())` için.
  AppDatabase(super.e);

  /// Uygulama için varsayılan dosya tabanlı veritabanı.
  AppDatabase.defaults() : super(driftDatabase(name: 'resonance'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Kural 9: Her yeni tablo için schemaVersion artırılır ve burada
          // sürüm sırasına göre migrasyon eklenir. Gün 6 itibarıyla v1.
          //
          // if (from < 2) await m.createTable(queueState);
          // if (from < 3) await m.createTable(customThemes);
          // if (from < 4) await m.createTable(equalizerPresets);
          // if (from < 5) await m.createTable(excludedFolders);
        },
        beforeOpen: (details) async {
          // Cascade silmelerin çalışması için FK zorunlu.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}