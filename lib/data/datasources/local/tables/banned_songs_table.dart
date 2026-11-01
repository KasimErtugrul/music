import 'package:drift/drift.dart';

/// Gün 17 (Kasa): kullanıcının yasakladığı şarkılar.
///
/// Temel sözleşme: diskteki dosyaya ASLA dokunulmaz (silinmez, taşınmaz,
/// şifrelenmez). Bu tablo yalnızca Resonance'ın hangi dosyaları hiçbir
/// listede göstermeyeceğine ve hiçbir koşulda çalmayacağına karar verir.
///
/// Yalnızca `songId` değil `path` de saklanır: MediaStore yeniden
/// taramalarında şarkı kimliği değişebilir; yol kalıcı kimliktir.
/// Başlık/sanatçı/albüm anlık görüntüleri, şarkı kitaplıktan düştükten
/// sonra bile kasa listesinin okunabilir kalmasını sağlar.
class BannedSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer()();

  /// Dosyanın kalıcı kimliği — yeniden taramada songId değişse bile
  /// yasak bu yol üzerinden devam eder.
  TextColumn get path => text().unique()();

  TextColumn get titleSnapshot => text()();
  TextColumn get artistSnapshot => text().nullable()();
  TextColumn get albumSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
