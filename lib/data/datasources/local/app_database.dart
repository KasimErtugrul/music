import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:resonance/data/datasources/local/daos/banned_song_dao.dart'; // YENİ (Gün 17)
import 'package:resonance/data/datasources/local/daos/custom_theme_dao.dart';
import 'package:resonance/data/datasources/local/daos/equalizer_preset_dao.dart';
import 'package:resonance/data/datasources/local/daos/excluded_folder_dao.dart';
import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/datasources/local/daos/queue_state_dao.dart';
import 'package:resonance/data/datasources/local/tables/banned_songs_table.dart'; // YENİ (Gün 17)
import 'package:resonance/data/datasources/local/tables/custom_themes_table.dart';
import 'package:resonance/data/datasources/local/tables/equalizer_presets_table.dart';
import 'package:resonance/data/datasources/local/tables/excluded_folders_table.dart';
import 'package:resonance/data/datasources/local/tables/favorites_table.dart';
import 'package:resonance/data/datasources/local/tables/lyrics_table.dart';
import 'package:resonance/data/datasources/local/tables/play_history_table.dart';
import 'package:resonance/data/datasources/local/tables/playlist_songs_table.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';
import 'package:resonance/data/datasources/local/tables/queue_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Playlists, PlaylistSongs, Favorites, PlayHistory, Lyrics, QueueStates,
    CustomThemes, EqualizerPresets, ExcludedFolders, BannedSongs, // YENİ
  ],
  daos: [
    PlaylistDao, FavoriteDao, HistoryDao, LyricsDao, QueueStateDao,
    CustomThemeDao, EqualizerPresetDao, ExcludedFolderDao, BannedSongDao, // YENİ
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.defaults() : super(_open());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createHistoryIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(queueStates);
          if (from < 3) {
            await m.addColumn(playlistSongs, playlistSongs.path);
            await m.addColumn(playlistSongs, playlistSongs.title);
            await m.addColumn(playlistSongs, playlistSongs.artist);
            await m.addColumn(playlistSongs, playlistSongs.durationMs);
          }
          if (from < 4) await m.createTable(customThemes);
          if (from < 5) {
            await m.addColumn(favorites, favorites.path);
            await m.addColumn(favorites, favorites.title);
            await m.addColumn(favorites, favorites.artist);
            await m.addColumn(favorites, favorites.durationMs);
            await m.addColumn(playHistory, playHistory.path);
            await m.addColumn(playHistory, playHistory.title);
            await m.addColumn(playHistory, playHistory.artist);
            await m.addColumn(playHistory, playHistory.durationMs);
          }
          if (from < 6) await m.createTable(equalizerPresets);
          if (from < 7) await m.createTable(excludedFolders); // YENİ
          if (from < 8) await m.createTable(bannedSongs); // Gün 17: Kasa
          if (from < 9) {
            // v9: eski kurulumlarda eksik olan UNIQUE kısıtlar (taze
            // kurulumda createAll bunları zaten oluşturuyordu) + geçmiş
            // indeksleri. Önce mükerrer satırlar temizlenir; yoksa UNIQUE
            // indeks oluşturma başarısız olur.
            await customStatement(
              'DELETE FROM favorites WHERE id NOT IN '
              '(SELECT MIN(id) FROM favorites GROUP BY song_id)',
            );
            await customStatement(
              'DELETE FROM playlist_songs WHERE id NOT IN '
              '(SELECT MIN(id) FROM playlist_songs '
              'GROUP BY playlist_id, song_id)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_favorites_song_id_u '
              'ON favorites (song_id)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS '
              'idx_playlist_songs_playlist_song_u '
              'ON playlist_songs (playlist_id, song_id)',
            );
            await _createHistoryIndexes();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Dinleme geçmişi sorguları (GROUP BY songId, tarih aralığı) için
  /// indeksler. IF NOT EXISTS ile idempotent.
  Future<void> _createHistoryIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_play_history_song_id '
      'ON play_history (song_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_play_history_played_at '
      'ON play_history (played_at)',
    );
  }
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'resonance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}