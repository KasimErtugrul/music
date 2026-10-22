import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/theme/theme_engine.dart';

abstract class ThemeRepository {
  Future<ThemeSettings?> loadActiveTheme();
  Future<void> saveActiveTheme(ThemeSettings settings);
}

class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'active_theme_settings';

  @override
  Future<ThemeSettings?> loadActiveTheme() async {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr == null) return null;
    try {
      return ThemeSettings.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveTheme(ThemeSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}