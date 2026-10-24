import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/excluded_folders_table.dart';

part 'excluded_folder_dao.g.dart';
 
@DriftAccessor(tables: [ExcludedFolders])
class ExcludedFolderDao extends DatabaseAccessor<AppDatabase> with _$ExcludedFolderDaoMixin {
  ExcludedFolderDao(super.db);

  Future<List<String>> getAllPaths() async {
    final rows = await select(excludedFolders).get();
    return rows.map((r) => r.path).toList();
  }

  Stream<List<ExcludedFolder>> watchAll() {
    return select(excludedFolders).watch();
  }

  Future<void> addPath(String path) {
    return into(excludedFolders).insert(
      ExcludedFoldersCompanion.insert(path: path),
    );
  }

  Future<void> removePath(String path) {
    return (delete(excludedFolders)..where((t) => t.path.equals(path))).go();
  }
}