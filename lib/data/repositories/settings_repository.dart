import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/settings/settings_defaults.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/data/models/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> load();
  Future<void> save(AppSettingsModel settings);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const int _schemaVersion = 1;
  static const String _schemaKey = 'settings_schema_version';

  @override
  Future<AppSettingsModel> load() async {
    await _migrateIfNeeded();

    return AppSettingsModel(
      languageCode: _prefs.getString(SettingsKeys.languageCode) ??
          SettingsDefaults.languageCode,
      themeMode: _prefs.getString(SettingsKeys.themeMode) ??
          SettingsDefaults.themeMode,
      dynamicColor: _prefs.getBool(SettingsKeys.dynamicColor) ??
          SettingsDefaults.dynamicColor,
      amoledDark:
          _prefs.getBool(SettingsKeys.amoledDark) ?? SettingsDefaults.amoledDark,
    );
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    await Future.wait(<Future<bool>>[
      _prefs.setString(SettingsKeys.languageCode, settings.languageCode),
      _prefs.setString(SettingsKeys.themeMode, settings.themeMode),
      _prefs.setBool(SettingsKeys.dynamicColor, settings.dynamicColor),
      _prefs.setBool(SettingsKeys.amoledDark, settings.amoledDark),
    ]);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> _migrateIfNeeded() async {
    final current = _prefs.getInt(_schemaKey) ?? 0;
    if (current >= _schemaVersion) return;
    // v0 → v1: anahtar şeması ilk sürüm, ekstra işlem yok.
    await _prefs.setInt(_schemaKey, _schemaVersion);
  }
}