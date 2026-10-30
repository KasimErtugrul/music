
import 'package:flutter/foundation.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/core/settings/settings_key_migration.dart';

class BackupDatasource {
  final AppDatabase _db;
  final SharedPreferences _prefs;

  BackupDatasource(this._db, this._prefs);

  Future<BackupModel> exportData() async {
    // 1. Playlists
    final playlistRows = await _db.playlistDao.getAll();
    final backupPlaylists = <BackupPlaylist>[];
    for (final p in playlistRows) {
      final songs = await _db.playlistDao.getSongsInPlaylist(p.id);
      backupPlaylists.add(BackupPlaylist(
        name: p.name,
        songs: songs.map((s) => BackupSong(
          uri: '', // Playlist songs tablosunda URI yok, sadece path var
          path: s.path ?? '',
          title: s.title ?? '',
          artist: s.artist,
          durationMs: s.durationMs ?? 0,
        )).toList(),
      ));
    }

    // 2. Favorites
    final favRows = await _db.favoriteDao.getAllSongIds();
    final backupFavs = <BackupSong>[];
    for (final id in favRows) {
      final f = await (_db.select(_db.favorites)..where((t) => t.songId.equals(id))).getSingleOrNull();
      if (f != null) {
        backupFavs.add(BackupSong(
          uri: '', // Favorites tablosunda URI yok, sadece path var
          path: f.path ?? '',
          title: f.title ?? '',
          artist: f.artist,
          durationMs: f.durationMs ?? 0,
        ));
      }
    }

    // 3. Themes
    final themeRows = await _db.customThemeDao.getAll();
    final backupThemes = themeRows.map((t) => BackupTheme(name: t.name, settingsJson: t.settingsJson)).toList();

    // 4. Equalizer
    final eqRows = await _db.equalizerPresetDao.getAll();
    final backupEq = eqRows.map((e) => BackupEqualizerPreset(name: e.name, bandsJson: e.bandsJson)).toList();

    // 5. Settings
    // Gün 1: kapsam artık SettingsPersistence.backupKeys açık listesinden
    // gelir. Eski davranış (yalnızca 'settings_' öneki + 3 sabit anahtar)
    // Çalma ve Kitaplık ayarlarını yedeğin dışında bırakıyordu.
    final settingsMap = collectBackedUpSettings(_prefs);

    return BackupModel(
      version: 1,
      playlists: backupPlaylists,
      favorites: backupFavs,
      customThemes: backupThemes,
      equalizerPresets: backupEq,
      settings: settingsMap,
    );
  }

  Future<void> importData(BackupModel backup) async {
    if (backup.version != 1) {
      // Sürüm uyuşmazlığı — uyarı göster, yine de devam et
    }

    await _db.transaction(() async {
      // 1. Temizle (Clear)
      await _db.delete(_db.playlistSongs).go();
      await _db.delete(_db.playlists).go();
      await _db.delete(_db.favorites).go();
      await _db.delete(_db.customThemes).go();
      await _db.delete(_db.equalizerPresets).go();

      // 2. Playlists
      for (final p in backup.playlists) {
        final newId = await _db.playlistDao.create(p.name);
        for (final s in p.songs) {
          await _db.playlistDao.addSong(newId, SongModel(
            id: 0, // Geçici, MediaStore ID'si bilinmiyor. Gün 13'teki "path+title+artist" eşleşmesi Gün 31'de eklenecek.
            uri: s.uri,
            path: s.path,
            title: s.title,
            artist: s.artist,
            durationMs: s.durationMs,
            sizeBytes: 0,
          ));
        }
      }

      // 3. Favorites
      for (final f in backup.favorites) {
        await _db.favoriteDao.add(SongModel(
          id: 0,
          uri: f.uri,
          path: f.path,
          title: f.title,
          artist: f.artist,
          durationMs: f.durationMs,
          sizeBytes: 0,
        ));
      }

      // 4. Themes
      for (final t in backup.customThemes) {
        await _db.customThemeDao.insert(t.name, t.settingsJson);
      }

      // 5. Equalizer
      for (final e in backup.equalizerPresets) {
        await _db.equalizerPresetDao.insert(e.name, e.bandsJson);
      }
    });

    // 6. Settings
    // Gün 1: tip güvenli içe aktarma — yalnızca bilinen yedek anahtarları
    // kabul eder, desteklenmeyen değer tiplerinde çökmez.
    await applyBackedUpSettings(_prefs, backup.settings);
  }

  /// Gün 1: dışa aktarılan ayar kümesi. Yalnızca
  /// [SettingsPersistence.backupKeys] içindeki ve prefs'te gerçekten var olan
  /// anahtarlar alınır. Test edilebilir olsun diye statiktir.
  static Map<String, Object?> collectBackedUpSettings(SharedPreferences prefs) {
    final out = <String, Object?>{};
    for (final key in SettingsPersistence.backupKeys) {
      final value = prefs.get(key);
      if (value != null) out[key] = value;
    }
    return out;
  }

    /// Gün 1: tip güvenli içe aktarma.
  ///
  /// * Yedekte olmayan anahtarlar DOKUNULMAZ (eksik alan = mevcut değer);
  ///   böylece eski yedeklerle geriye dönük uyum korunur.
  /// * Yedekteki bilinmeyen (listede olmayan) anahtarlar yok sayılır.
  /// * Gün 10: geçerli adıyla bulunamayan anahtar, önce eski adıyla arama
  ///   yapılır (SettingsKeyMigration.legacyKeys) — bir anahtar yeniden
  ///   adlandırıldığında eski yedeklerin geri yüklenmesi kırılmaz. Harita
  ///   bugün boştur; [legacyKeys] test enjeksiyonu içindir.
  /// * Desteklenmeyen değer tipi olan anahtar atlanır; tek bir hatalı değer
  ///   tüm içe aktarmayı durdurmaz.
  static Future<void> applyBackedUpSettings(
    SharedPreferences prefs,
    Map<String, dynamic> raw, {
    Map<String, String> legacyKeys = SettingsKeyMigration.legacyKeys,
  }) async {
    for (final key in SettingsPersistence.backupKeys) {
      var val = raw[key];
      if (val == null) {
        // Gün 10: geçerli ada yedekte yer yoksa eski adı denenir; geçerli
        // ad yedekte VARSA eski ad hiç sorgulanmaz (yeni kazanır).
        for (final entry in legacyKeys.entries) {
          if (entry.value != key) continue;
          final legacyVal = raw[entry.key];
          if (legacyVal != null) {
            val = legacyVal;
            break;
          }
        }
      }
      if (val == null) continue;
      try {
        if (val is String) {
          await prefs.setString(key, val);
        } else if (val is bool) {
          await prefs.setBool(key, val);
        } else if (val is int) {
          await prefs.setInt(key, val);
        } else if (val is double) {
          await prefs.setDouble(key, val);
        } else if (val is List && val.every((e) => e is String)) {
          await prefs.setStringList(key, val.cast<String>());
        }
        // Desteklenmeyen tip → yok say.
      } on Object catch (e) {
        // Tek bir anahtarın yazımı başarısız olsa da içe aktarma devam eder.
        debugPrint('Ayar içe aktarılamadı ($key): $e');
      }
    }
  }
}