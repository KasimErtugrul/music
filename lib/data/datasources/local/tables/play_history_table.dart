import 'package:drift/drift.dart';

class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();
  TextColumn get path => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}