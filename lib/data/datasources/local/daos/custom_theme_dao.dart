import 'package:drift/drift.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/tables/custom_themes_table.dart';

part 'custom_theme_dao.g.dart';

@DriftAccessor(tables: [CustomThemes])
class CustomThemeDao extends DatabaseAccessor<AppDatabase>
    with _$CustomThemeDaoMixin {
  CustomThemeDao(super.db);

  Stream<List<CustomTheme>> watchAll() =>
      (select(customThemes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<CustomTheme>> getAll() =>
      (select(customThemes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<int> insert(String name, String settingsJson) {
    return into(customThemes).insert(
      CustomThemesCompanion.insert(name: name, settingsJson: settingsJson),
    );
  }

  Future<void> updateTheme(int id, String name, String settingsJson) {
    return (update(customThemes)..where((t) => t.id.equals(id))).write(
      CustomThemesCompanion(
        name: Value(name),
        settingsJson: Value(settingsJson),
      ),
    );
  }

  Future<void> deleteTheme(int id) {
    return (delete(customThemes)..where((t) => t.id.equals(id))).go();
  }
}