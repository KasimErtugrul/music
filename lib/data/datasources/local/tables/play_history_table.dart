import 'package:drift/drift.dart';

/// Her çalma olayı bir satır. "En çok çalınanlar" GROUP BY ile hesaplanır.
/// Çalındı sayılma eşiği Gün 14'te repository katmanında tanımlanacak.
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}