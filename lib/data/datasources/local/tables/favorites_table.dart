import 'package:drift/drift.dart';

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();
  TextColumn get path => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [{songId}];
}