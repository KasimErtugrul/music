import 'package:resonance/data/datasources/backup_datasource.dart';
import 'package:resonance/data/models/backup_model.dart';

abstract class BackupRepository {
  Future<BackupModel> export();
  Future<void> import(BackupModel data);
}

class BackupRepositoryImpl implements BackupRepository {
  final BackupDatasource _datasource;
  BackupRepositoryImpl(this._datasource);

  @override
  Future<BackupModel> export() => _datasource.exportData();

  @override
  Future<void> import(BackupModel data) => _datasource.importData(data);
}