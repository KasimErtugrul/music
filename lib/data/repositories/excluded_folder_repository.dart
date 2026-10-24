import 'package:resonance/data/datasources/local/daos/excluded_folder_dao.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';

abstract class ExcludedFolderRepository {
  Future<List<ExcludedFolderModel>> getExcludedFolders();
  Future<void> addFolder(String path);
  Future<void> removeFolder(String path);
}

class ExcludedFolderRepositoryImpl implements ExcludedFolderRepository {
  final ExcludedFolderDao _dao;
  ExcludedFolderRepositoryImpl(this._dao);

  @override
  Future<List<ExcludedFolderModel>> getExcludedFolders() async {
    final rows = await _dao.getAllPaths();
    // ID'ye ihtiyacımız yok, sadece yollar lazım ama Model'e çeviriyoruz (Kural 3)
    return rows.map((p) => ExcludedFolderModel(id: 0, path: p)).toList();
  }

  @override
  Future<void> addFolder(String path) => _dao.addPath(path);

  @override
  Future<void> removeFolder(String path) => _dao.removePath(path);
}