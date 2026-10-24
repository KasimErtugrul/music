import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/equalizer_presets_table.dart';

part 'equalizer_preset_dao.g.dart';

@DriftAccessor(tables: [EqualizerPresets])
class EqualizerPresetDao extends DatabaseAccessor<AppDatabase> with _$EqualizerPresetDaoMixin {
  EqualizerPresetDao(super.db);

  Future<List<EqualizerPreset>> getAll() {
    return (select(equalizerPresets)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Stream<List<EqualizerPreset>> watchAll() {
    return (select(equalizerPresets)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<int> insert(String name, String bandsJson) {
    return into(equalizerPresets).insert(
      EqualizerPresetsCompanion.insert(name: name, bandsJson: bandsJson),
    );
  }

  Future<void> deletePreset(int id) {
    return (delete(equalizerPresets)..where((t) => t.id.equals(id))).go();
  }
}