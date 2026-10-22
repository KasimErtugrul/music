import 'dart:convert';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/datasources/local/daos/custom_theme_dao.dart';
import 'package:resonance/data/models/custom_theme_model.dart';

abstract class CustomThemeRepository {
  Stream<List<CustomThemeModel>> watchAll();
  Future<int> saveTheme(String name, ThemeSettings settings);
  Future<void> updateTheme(int id, String name, ThemeSettings settings);
  Future<void> deleteTheme(int id);
}

class CustomThemeRepositoryImpl implements CustomThemeRepository {
  CustomThemeRepositoryImpl(this._dao);
  final CustomThemeDao _dao;

  @override
  Stream<List<CustomThemeModel>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map((r) {
          final settings = ThemeSettings.fromJson(jsonDecode(r.settingsJson));
          return CustomThemeModel(id: r.id, name: r.name, settings: settings);
        }).toList());
  }

  @override
  Future<int> saveTheme(String name, ThemeSettings settings) {
    return _dao.insert(name, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> updateTheme(int id, String name, ThemeSettings settings) {
    return _dao.updateTheme(id, name, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> deleteTheme(int id) => _dao.deleteTheme(id);
}