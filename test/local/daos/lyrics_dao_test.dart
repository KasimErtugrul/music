import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';

void main() {
  late AppDatabase db;
  late LyricsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.lyricsDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert inserts then updates', () async {
    await dao.upsert(1, 'line 1', source: 'lrc');
    var row = await dao.get(1);
    expect(row!.content, 'line 1');
    expect(row.source, 'lrc');

    await dao.upsert(1, 'line 1 updated');
    row = await dao.get(1);
    expect(row!.content, 'line 1 updated');
    expect(row.source, 'manual');
  });

  test('deleteFor removes row', () async {
    await dao.upsert(1, 'x');
    await dao.deleteFor(1);
    expect(await dao.get(1), isNull);
  });
}