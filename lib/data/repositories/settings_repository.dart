import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/settings/settings_defaults.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/data/models/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> load();
  Future<void> setString(String key, String value);
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<AppSettingsModel> load() async {
    return AppSettingsModel(
      languageCode: _prefs.getString(SettingsKeys.languageCode) ??
          SettingsDefaults.languageCode,
    );
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
}