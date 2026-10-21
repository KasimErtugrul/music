import 'package:drift/drift.dart';

/// Favori şarkılar. Yalnızca bu tablo favori durumunu tutar (kural 5).
///
/// `id`: monotonik, `INSERT OR REPLACE` yeniden ekleme sırasında büyür →
/// "en yeni önce" sıralaması `addedAt` timestamp hassasiyetinden bağımsız
/// kararlı çalışır (`CURRENT_TIMESTAMP` saniye çözünürlüğündedir).
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {songId},
      ];
}