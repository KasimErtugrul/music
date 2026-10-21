import 'package:drift/drift.dart';

/// Uygulama kapatıldığında son kuyruğu ve oynatma konumunu tutan tablo.
/// Her zaman tek satır (id=1) bulunur.
class QueueStates extends Table {
  IntColumn get id => integer()();
  TextColumn get songUris => text()();
  IntColumn get currentIndex => integer()();
  IntColumn get positionMs => integer()();
  BoolColumn get shuffleEnabled => boolean()();
  IntColumn get repeatMode => integer()();
  TextColumn get shuffleOrder => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}