import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'schemaVersion is 7 '
    '(v1: base, v2: queue_states, v3: playlist fallback, v4: custom_themes, '
    'v5: favorites/history fallback, v6: equalizer_presets, v7: excluded_folders)',
    () {
      expect(db.schemaVersion, 7);
    },
  );

  test('onCreate creates all current tables', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll(<String>[
        'playlists',
        'playlist_songs',
        'favorites',
        'play_history',
        'lyrics',
        'queue_states',
        'custom_themes',
        'equalizer_presets',
        'excluded_folders',
      ]),
    );
  });

  test('foreign keys are enabled', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });
}