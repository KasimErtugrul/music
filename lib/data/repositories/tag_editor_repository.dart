import 'package:resonance/data/datasources/metadata_datasource.dart';
import 'package:resonance/data/models/tag_model.dart';

abstract class TagEditorRepository {
  Future<TagModel?> readTags(String filePath);
}

class TagEditorRepositoryImpl implements TagEditorRepository {
  final MetadataDatasource _datasource;
  TagEditorRepositoryImpl(this._datasource);

  @override
  Future<TagModel?> readTags(String filePath) => _datasource.readTags(filePath);
}