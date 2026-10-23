import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';

abstract class PreferencesRepository {
  Future<PlaybackSettingsModel> loadPlayback();
  Future<LibrarySettingsModel> loadLibrary();
  Future<void> savePlayback(PlaybackSettingsModel settings);
  Future<void> saveLibrary(LibrarySettingsModel settings);
  Future<void> resetAll();
}

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const _kPlayback = 'playback_settings';
  static const _kLibrary = 'library_settings';

  @override
  Future<PlaybackSettingsModel> loadPlayback() async {
    final json = _prefs.getString(_kPlayback);
    if (json == null) return const PlaybackSettingsModel();
    return PlaybackSettingsModel.fromJson(jsonDecode(json));
  }

  @override
  Future<LibrarySettingsModel> loadLibrary() async {
    final json = _prefs.getString(_kLibrary);
    if (json == null) return const LibrarySettingsModel();
    return LibrarySettingsModel.fromJson(jsonDecode(json));
  }

  @override
  Future<void> savePlayback(PlaybackSettingsModel settings) async {
    await _prefs.setString(_kPlayback, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> saveLibrary(LibrarySettingsModel settings) async {
    await _prefs.setString(_kLibrary, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> resetAll() async {
    await _prefs.remove(_kPlayback);
    await _prefs.remove(_kLibrary);
  }
}