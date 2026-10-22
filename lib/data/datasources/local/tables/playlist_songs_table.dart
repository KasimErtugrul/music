import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';

class PlaylistSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId => integer()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  // Gün 13: ID değişirse eşleştirme için fallback verileri
  TextColumn get path => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {playlistId, songId},
      ];
}