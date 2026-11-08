// Gün 9 testi: Gün 7 raporundaki «içe aktarma/geri yükleme sonrası
// favorites Rx durumu bayat kalıyor» kaydının DÜZELTMESİ.
//
// FavoriteController onInit'te FavoriteRepository.watchFavoriteIds()
// akışına abone olur; FavoriteDao.watchAllSongIds() Drift'in CANLI sorgu
// akışıdır (.watch()). Yedek içe aktarma favorites tablosunu silip yeniden
// kurduğunda (BackupDatasource.importData) akış kendiliğinden yeniden
// yayınlar ve Rx durum reload'suz güncellenir — FavoriteController için
// reload() gerekmez. Gün 7 kaydının favoriler yarısı bu testle pinlenir
// (gerçek bellek-içi Drift veritabanıyla; mock yok).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/data/datasources/local/app_database.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'uri/$id',
      path: '/path/$id.mp3',
      title: 'Song $id',
      durationMs: 1000,
      sizeBytes: 100,
    );

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    Get.testMode = true;
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  test(
      'favorites tablosu silinip yeniden kurulunca Rx durum '
      'reload\u2019suz güncellenir', () async {
    final dao = db.favoriteDao;
    final repo = FavoriteRepositoryImpl(dao);
    final controller = Get.put<FavoriteController>(FavoriteController(repo));

    // İlk yayın: boş tablo.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(controller.favoriteIds, isEmpty);

    // DB'ye dışarıdan yazım (kullanıcı favori ekliyor):
    await repo.toggleFavorite(_song(1));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(controller.favoriteIds, <int>{1});

    // İçe aktarma davranışı: BackupDatasource.importData favorites
    // tablosunu silip yeniden kurar; canlı akış farkı hemen yayınlar:
    await (db.delete(db.favorites)).go();
    await dao.add(_song(2));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // reload() çağrısı YOK: durum akışla günceldi (Gün 7 kaydının
    // düzeltmesi — FavoriteController'a reload eklenmesi gereksizdi).
    expect(controller.favoriteIds, <int>{2});
  });
}