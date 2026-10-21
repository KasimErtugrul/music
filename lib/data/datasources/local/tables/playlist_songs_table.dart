import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/tables/playlists_table.dart';

/// Playlist ↔ şarkı ilişkisi. Sıralama [position] ile tutulur.
/// Aynı şarkı aynı playlist'e iki kez eklenemez (composite unique).
class PlaylistSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId => integer()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {playlistId, songId},
      ];
}