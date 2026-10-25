
import 'package:resonance/data/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/models/backup_model.dart';

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
    final settingsMap = <String, dynamic>{};
    for (final key in _prefs.getKeys()) {
      // Sadece uygulamaya özel anahtarları (ör. 'settings_') al
      if (key.startsWith('settings_') || key == 'language_code' || key == 'active_theme_settings' || key == 'equalizer_enabled') {
        settingsMap[key] = _prefs.get(key);
      }
    }

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
    for (final entry in backup.settings.entries) {
      final val = entry.value;
      if (val is String) await _prefs.setString(entry.key, val);
      else if (val is bool) await _prefs.setBool(entry.key, val);
      else if (val is int) await _prefs.setInt(entry.key, val);
      else if (val is double) await _prefs.setDouble(entry.key, val);
    }
  }
}