import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/history_dao.dart';

void main() {
  late AppDatabase db;
  late HistoryDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.historyDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('recordPlay inserts a row', () async {
    await dao.recordPlay(7);
    final recent = await dao.watchRecent().first;
    expect(recent.length, 1);
    expect(recent.first.songId, 7);
  });

  test('getMostPlayed aggregates by songId and orders by count', () async {
    for (var i = 0; i < 3; i++) {
      await dao.recordPlay(1);
    }
    for (var i = 0; i < 2; i++) {
      await dao.recordPlay(2);
    }
    await dao.recordPlay(3);

    final most = await dao.getMostPlayed();
    expect(most.map((e) => e.songId).toList(), <int>[1, 2, 3]);
    expect(most.map((e) => e.playCount).toList(), <int>[3, 2, 1]);
  });

  test('clear removes all rows', () async {
    await dao.recordPlay(1);
    await dao.clear();
    expect(await dao.watchRecent().first, isEmpty);
  });
}