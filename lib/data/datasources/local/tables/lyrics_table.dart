import 'package:drift/drift.dart';

/// Şarkı sözü. Kaynak: `embedded`, `lrc`, `manual`.
class Lyrics extends Table {
  IntColumn get songId => integer()();
  TextColumn get content => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}