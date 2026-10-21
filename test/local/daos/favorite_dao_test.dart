import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/favorite_dao.dart';

void main() {
  late AppDatabase db;
  late FavoriteDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.favoriteDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('add + isFavorite + remove', () async {
    expect(await dao.isFavorite(1), isFalse);
    await dao.add(1);
    expect(await dao.isFavorite(1), isTrue);
    await dao.remove(1);
    expect(await dao.isFavorite(1), isFalse);
  });

  test('add is idempotent (primary key conflict)', () async {
    await dao.add(1);
    await dao.add(1);
    expect((await dao.getAllSongIds()).length, 1);
  });

  test('getAllSongIds returns newest first', () async {
    await dao.add(1);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await dao.add(2);
    final ids = await dao.getAllSongIds();
    expect(ids, <int>[2, 1]);
  });
}