// Aşama 6: Otomatik yedekleme — repository katmanı.
//
// Dosya I/O AutoBackupStorage'da, yedek modeli üretimi mevcut
// BackupRepository.export()'tan gelir. Böylece otomatik yedek, manuel
// yedekle aynı model sözleşmesini (BackupModel v1) paylaşır.
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/repositories/backup_repository.dart';

abstract class AutoBackupRepository {
  Future<List<AutoBackupEntry>> list();
  Future<AutoBackupEntry> create();
  Future<BackupModel?> read(AutoBackupEntry entry);
  Future<void> delete(AutoBackupEntry entry);
  Future<void> prune(int keepCount);
}

class AutoBackupRepositoryImpl implements AutoBackupRepository {
  AutoBackupRepositoryImpl(this._backupRepo, this._storage);

  final BackupRepository _backupRepo;
  final AutoBackupStorage _storage;

  @override
  Future<List<AutoBackupEntry>> list() => _storage.list();

  @override
  Future<AutoBackupEntry> create() async =>
      _storage.write(await _backupRepo.export());

  @override
  Future<BackupModel?> read(AutoBackupEntry entry) => _storage.read(entry);

  @override
  Future<void> delete(AutoBackupEntry entry) => _storage.delete(entry);

  @override
  Future<void> prune(int keepCount) => _storage.prune(keepCount);
}
