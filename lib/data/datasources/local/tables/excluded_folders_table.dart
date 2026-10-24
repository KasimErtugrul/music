import 'package:drift/drift.dart';

class ExcludedFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}