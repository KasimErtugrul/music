// Bulgu 6: şarkı sözü denetleyicisi sözleşmesi.
//
// Veri katmanı (Lyrics tablosu + LyricsDao, şema v9) hazırdı; bu testler
// denetleyicinin onu doğru sardığını kilitler:
// * save → DB upsert + önbellek güncel; boş içerik silme anlamına gelir.
// * loadFor olmayan sözü null döndürür ve önbellekte tutmaz.
// * remove DB'den siler, önbellekten düşer.
// * looksLikeLrc yalnız gerçek zaman damgalı içeriği eşzamanlı sayar.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';
import 'package:resonance/presentation/controllers/lyrics_controller.dart';

void main() {
  late AppDatabase db;
  late LyricsController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    controller = LyricsController(LyricsDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('save yazar ve önbelleğe koyar; loadFor geri okur', () async {
    await controller.save(1, 'Bir yaz gecesi\nUzun yol');

    expect(controller.contentOf(1), 'Bir yaz gecesi\nUzun yol');

    // Önbellek dışı bir örnekten DB gerçekliği doğrulanır.
    final fresh = LyricsController(LyricsDao(db));
    expect(await fresh.loadFor(1), 'Bir yaz gecesi\nUzun yol');
  });

  test('boş içerik kaydı sözü siler (upsert yerine delete)', () async {
    await controller.save(2, 'söz');
    await controller.save(2, '   ');

    expect(controller.contentOf(2), isNull);
    expect(await LyricsDao(db).get(2), isNull);
  });

  test('loadFor olmayan sözü null döndürür', () async {
    expect(await controller.loadFor(99), isNull);
    expect(controller.contentOf(99), isNull);
  });

  test('remove DB ve önbellekten birlikte düşer', () async {
    await controller.save(3, 'söz üç');
    await controller.remove(3);

    expect(controller.contentOf(3), isNull);
    expect(await LyricsDao(db).get(3), isNull);
  });

  group('looksLikeLrc', () {
    test('zaman damgalı satırlar eşzamanlı sayılır', () {
      expect(
        LyricsController.looksLikeLrc('[00:12.50] ilk satır\n[00:20.00] ikinci'),
        isTrue,
      );
      expect(
        LyricsController.looksLikeLrc('[01:02] dakika biçimi\n[01:20] devam'),
        isTrue,
      );
    });

    test('düz metin ve tek etiket eşzamanlı sayılmaz', () {
      expect(LyricsController.looksLikeLrc('sadece düz metin\nikinci satır'),
          isFalse);
      expect(LyricsController.looksLikeLrc('[00:10.00] tek satır'), isFalse);
      expect(LyricsController.looksLikeLrc('[ti:Başlık]\ndüz metin'), isFalse);
    });
  });
}
