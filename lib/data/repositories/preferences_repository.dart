import 'dart:convert';
import 'package:resonance/core/settings/settings_persistence.dart';
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

  // Gün 1: anahtar dizgeleri SettingsPersistence'tan gelir; yedek listesiyle
  // ayrışamaz (tek doğruluk kaynağı).
  static const _kPlayback = SettingsPersistence.playbackSettings;
  static const _kLibrary = SettingsPersistence.librarySettings;

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
    // Gün 6: "Tüm ayarları sıfırla" artık adına uygun. Taban kodda yalnız
    // playback/library siliniyordu; tema, ekolayzer, widget, arama geçmişi,
    // dil ve otomatik yedek tercihleri sıfırlamaya girmiyordu (üstelik
    // hiçbir ekran bu metodu çağırmıyordu — Gün 6'da bağlandı). Şimdi
    // SettingsPersistence.backupKeys'ün TAMAMI kaldırılır: anahtar yokluğu
    // fabrika varsayılanı demektir (loadPlayback/loadLibrary zaten null'da
    // varsayılana düşer; diğer katmanlar kendi repo'larında aynen böyle).
    // Zamansal iş-bilgisi anahtarları (SettingsPersistence.notBackedUpKeys:
    // son yedek zaman damgaları) ayar olmadığı için bilinçli olarak korunur.
    for (final key in SettingsPersistence.backupKeys) {
      await _prefs.remove(key);
    }
  }
}