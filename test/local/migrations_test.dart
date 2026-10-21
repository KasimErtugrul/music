import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates v1 to v2 adding queue_states', () async {
    final file = File('migration_test.sqlite');
    if (file.existsSync()) file.deleteSync();
    
    final db = sqlite3.open(file.path);
    db.execute('PRAGMA user_version = 1;');
    // v1 Tabloları
    db.execute('''
      CREATE TABLE playlists (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
      CREATE TABLE playlist_songs (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE, song_id INTEGER NOT NULL, position INTEGER NOT NULL, added_at INTEGER NOT NULL);
      CREATE TABLE favorites (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, song_id INTEGER NOT NULL, added_at INTEGER NOT NULL);
      CREATE TABLE play_history (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, song_id INTEGER NOT NULL, played_at INTEGER NOT NULL);
      CREATE TABLE lyrics (song_id INTEGER NOT NULL PRIMARY KEY, content TEXT NOT NULL, source TEXT NOT NULL DEFAULT 'manual', updated_at INTEGER NOT NULL);
    ''');
    db.close();
    
    // AppDatabase v2'yi aynı dosya üzerinde aç
    final appDb = AppDatabase(NativeDatabase(file));
    final tables = await appDb.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='queue_states'").get();
    
    expect(tables, isNotEmpty);
    await appDb.close();
    file.deleteSync();
  });
}