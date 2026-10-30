import 'dart:convert';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/theme/theme_engine.dart';

abstract class ThemeRepository {
  Future<ThemeSettings?> loadActiveTheme();
  Future<void> saveActiveTheme(ThemeSettings settings);
}

class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;
  // Gün 1: anahtar SettingsPersistence'tan gelir (yedek listesiyle uyumlu).
  static const _key = SettingsPersistence.activeThemeSettings;

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