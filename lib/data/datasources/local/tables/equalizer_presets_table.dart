import 'package:drift/drift.dart';

class EqualizerPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get bandsJson => text()(); // Bant kazançları JSON olarak
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}