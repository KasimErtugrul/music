import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:resonance/data/datasources/local/daos/custom_theme_dao.dart';
import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/datasources/local/daos/queue_state_dao.dart';
import 'package:resonance/data/datasources/local/tables/custom_themes_table.dart';
import 'package:resonance/data/datasources/local/tables/favorites_table.dart';
import 'package:resonance/data/datasources/local/tables/lyrics_table.dart';
import 'package:resonance/data/datasources/local/tables/play_history_table.dart';
import 'package:resonance/data/datasources/local/tables/playlist_songs_table.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';
import 'package:resonance/data/datasources/local/tables/queue_state_table.dart';
import 'package:resonance/data/datasources/local/tables/equalizer_presets_table.dart';
import 'package:resonance/data/datasources/local/daos/equalizer_preset_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Playlists, PlaylistSongs, Favorites, PlayHistory, Lyrics, QueueStates,
    CustomThemes, EqualizerPresets, // YENİ
  ],
  daos: [
    PlaylistDao, FavoriteDao, HistoryDao, LyricsDao, QueueStateDao,
    CustomThemeDao, EqualizerPresetDao,// YENİ
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.defaults() : super(_open());

  @override
  int get schemaVersion => 6;

 @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
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
          if (from < 6) await m.createTable(equalizerPresets); // YENİ
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'resonance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}