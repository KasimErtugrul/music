// Gün 7 testi: canlı ayar yeniden yükleme zinciri (reloadLiveSettingsControllers).
//
// Kapsam:
// * Gün 1'deki BackupController'a özel zincir Gün 7'de tek paylaşılan
//   fonksiyona çıkarıldı ve Gün 6'da reload() kazanan AppSearchController
//   ile AutoBackupController'ı da kapsıyor (Gün 6 raporundaki kayıtlı boşluk).
// * AutoBackupController.restore() (otomatik yedek geri yükleme) artık aynı
//   zinciri tetikler: geri yükleme ayarları diske uygular; uygulama
//   yeniden başlatmadan canlı durum güncellenir — manuel içe aktarma ile
//   aynı sözleşme (Gün 1). Gün 7'ye kadar bu yolda hiçbir controller
//   tazelenmiyordu.
// * Gün 9: aynı dosyaya ayar zincirinden AYRI ikinci tazeleme eklendi —
//   reloadLivePlaylistControllers. Çalma listeleri bir ayar değildir
//   (backupKeys kapsamı dışı); içe aktarma tabloyu silip yeniden kurar,
//   canlı PlaylistController tazelenir. Hiç açılmamış örnek
//   örneklendirilmez (isPrepared koruması).
//
// Neden gerçek WidgetsFlutterBinding (testWidgets DEĞİL): Gün 1/Gün 6
// testlerindeki belgelenmiş düzenle aynı — Get.updateLocale zincirleri
// "await endOfFrame" ile biten performReassemble çağırır; gerçek binding
// ile zero-timer zincirleri doğal biçimde tamamlanır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/bindings/playlist_binding.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/live_settings_reload.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLibraryRepo extends Mock implements LibraryRepository {}

class _MockAutoRepo extends Mock implements AutoBackupRepository {}

class _MockBackupRepo extends Mock implements BackupRepository {}

class _MockPlaylistRepo extends Mock implements PlaylistRepository {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late _MockLibraryRepo libraryRepo;
  late _MockAutoRepo autoRepo;
  late _MockBackupRepo backupRepo;

  setUp(() {
    Get.testMode = true;
    libraryRepo = _MockLibraryRepo();
    autoRepo = _MockAutoRepo();
    backupRepo = _MockBackupRepo();
    // onInit'teki liste tazelemesi için:
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
  });

  tearDown(() async {
    Get.reset();
  });

  /// Yalnızca Gün 7 kapsamındaki iki anahtar ailesi tohumlanır; diğer
  /// controller'lar bu testlerde kayıtsız bırakılır (atlanma yolu da böylece
  /// her çağrıda fiilen çalışır).
  Future<SharedPreferences> seededPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SettingsPersistence.searchHistory: '["ada","beat"]',
      SettingsPersistence.autoBackupEnabled: false,
      SettingsPersistence.autoBackupFrequency: 'weekly',
      SettingsPersistence.autoBackupKeep: 3,
    });
    return SharedPreferences.getInstance();
  }

  group('reloadLiveSettingsControllers (Gün 7)', () {
    test('AppSearchController geçmişi diskten yeniden okur', () async {
      final prefs = await seededPrefs();
      Get.put<SharedPreferences>(prefs);
      final search = Get.put<AppSearchController>(
        AppSearchController(libraryRepo),
      );
      expect(search.searchHistory, <String>['ada', 'beat']);

      // Canlı durum diskten sapmış olsun (kullanıcı geçmişi temizledi ama
      // disk henüz güncel; ya da tersi — zincir diskteki gerçek durumu getirir).
      search.searchHistory.clear();

      await reloadLiveSettingsControllers();

      expect(search.searchHistory, <String>['ada', 'beat']);
    });

    test('AutoBackupController tercihleri diskten yeniden okur', () async {
      final prefs = await seededPrefs();
      final auto = Get.put<AutoBackupController>(
        AutoBackupController(
          autoRepo: autoRepo,
          backupRepo: backupRepo,
          libraryRepo: libraryRepo,
          prefs: prefs,
        ),
      );
      expect(auto.enabled.value, isFalse);
      expect(auto.frequency.value, AutoBackupFrequency.weekly);

      await prefs.setBool(SettingsPersistence.autoBackupEnabled, true);
      await prefs.setString(
          SettingsPersistence.autoBackupFrequency, AutoBackupFrequency.daily);

      await reloadLiveSettingsControllers();

      expect(auto.enabled.value, isTrue);
      expect(auto.frequency.value, AutoBackupFrequency.daily);
    });

    test('kayıtsız controller\u2019lar sessizce atlanır; akış tamamlanır',
        () async {
      await seededPrefs();
      // Hiçbir canlı controller kayıtlı değil: zincir fırlatmadan biter.
      await reloadLiveSettingsControllers();
    });
  });

  group('AutoBackupController.restore canlı yeniden yükleme (Gün 7)', () {
    test('geri yükleme sonrası ayarlar canlı controller\u2019lara yansır',
        () async {
      final prefs = await seededPrefs();
      Get.put<SharedPreferences>(prefs);

      final search = Get.put<AppSearchController>(
        AppSearchController(libraryRepo),
      );
      final auto = Get.put<AutoBackupController>(
        AutoBackupController(
          autoRepo: autoRepo,
          backupRepo: backupRepo,
          libraryRepo: libraryRepo,
          prefs: prefs,
        ),
      );

      // Canlı durum, geri yüklenecek yedekten sapkın:
      search.searchHistory.clear();
      expect(auto.enabled.value, isFalse);

      final entry = AutoBackupEntry(
        fileName: 'resonance_auto_1799999999999.json',
        path: '/fake/backups/resonance_auto_1799999999999.json',
        createdAt: DateTime(2026, 10, 31, 9, 30),
        sizeBytes: 128,
      );
      final model = BackupModel(
        settings: <String, dynamic>{
          SettingsPersistence.searchHistory: '["metallica","megadeth"]',
          SettingsPersistence.autoBackupEnabled: true,
        },
        playlists: const [],
        favorites: const [],
        customThemes: const [],
        equalizerPresets: const [],
      );

      // Gerçek veri katmanı davranışı: import ayarları diske uygular
      // (BackupDatasource.importData sonunda applyBackedUpSettings çağırır).
      when(() => autoRepo.read(entry)).thenAnswer((_) async => model);
      when(() => backupRepo.import(model)).thenAnswer((_) async {
        await prefs.setString(SettingsPersistence.searchHistory,
            '["metallica","megadeth"]');
        await prefs.setBool(SettingsPersistence.autoBackupEnabled, true);
      });
      when(() => libraryRepo.rescan()).thenAnswer((_) async {});

      final ok = await auto.restore(entry);
      expect(ok, isTrue);

      // Uygulama yeniden başlatmadan canlı durum yedekteki hale döner:
      expect(search.searchHistory, <String>['metallica', 'megadeth']);
      expect(auto.enabled.value, isTrue);
    });
  });

  group('reloadLivePlaylistControllers (Gün 9)', () {
    test('canlı PlaylistController listeyi yeniden okur', () async {
      await seededPrefs();
      final playlistRepo = _MockPlaylistRepo();
      final fresh = <PlaylistModel>[
        PlaylistModel(
          id: 1,
          name: 'Rock',
          songCount: 2,
          updatedAt: DateTime(2026, 10, 31, 10),
        ),
      ];
      when(() => playlistRepo.getPlaylists()).thenAnswer((_) async => fresh);
      final playlists = Get.put<PlaylistController>(
        PlaylistController(playlistRepo),
      );
      // onInit'in ilk yüklemesi tamamlanır:
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(playlists.playlists.length, 1);

      // Canlı durum diskten sapkın: içe aktarma tabloyu değiştirdi ama
      // controller eski listeyi gösteriyor (Gün 7 raporundaki boşluk):
      playlists.playlists.clear();

      await reloadLivePlaylistControllers();

      expect(playlists.playlists.length, 1);
      expect(playlists.playlists.first.name, 'Rock');
    });

    test('kayıtlı ama hiç açılmamış controller örneklendirilmez', () async {
      await seededPrefs();
      // PlaylistBinding yalnız lazyPut fabrikası kurar (isInit=false) —
      // uygulama açılışındaki gerçek duruma birebir eşdeğerdir:
      PlaylistBinding().dependencies();
      expect(Get.isRegistered<PlaylistController>(), isTrue);
      expect(Get.isPrepared<PlaylistController>(), isTrue);

      await reloadLivePlaylistControllers();

      // Hiç açılmamışsa örnek OLUŞTURULMAZ; sayfa ilk açıldığında onInit
      // zaten taze veri yükler. Her içe aktarmada gereksiz örnekleme yok:
      expect(Get.isPrepared<PlaylistController>(), isTrue);
    });

    test('restore sonrası çalma listeleri canlı controller\u2019a yansır',
        () async {
      final prefs = await seededPrefs();
      Get.put<SharedPreferences>(prefs);

      final auto = Get.put<AutoBackupController>(
        AutoBackupController(
          autoRepo: autoRepo,
          backupRepo: backupRepo,
          libraryRepo: libraryRepo,
          prefs: prefs,
        ),
      );

      // Gerçek veri katmanı davranışı: repository her okumada tablonun O
      // anki durumunu döndürür; import (backupRepo.import) tabloyu silip
      // yeniden kurar. Restore öncesi liste boş, sonrasında doludur:
      final playlistRepo = _MockPlaylistRepo();
      final fresh = <PlaylistModel>[
        PlaylistModel(
          id: 7,
          name: 'Yedekten',
          songCount: 3,
          updatedAt: DateTime(2026, 10, 31, 11),
        ),
      ];
      var imported = false;
      when(() => playlistRepo.getPlaylists()).thenAnswer((_) async {
        return imported ? fresh : <PlaylistModel>[];
      });
      final playlists = Get.put<PlaylistController>(
        PlaylistController(playlistRepo),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(playlists.playlists, isEmpty);

      final entry = AutoBackupEntry(
        fileName: 'resonance_auto_1799999999999.json',
        path: '/fake/backups/resonance_auto_1799999999999.json',
        createdAt: DateTime(2026, 10, 31, 9, 30),
        sizeBytes: 128,
      );
      final model = BackupModel(
        settings: <String, dynamic>{},
        playlists: const [],
        favorites: const [],
        customThemes: const [],
        equalizerPresets: const [],
      );
      when(() => autoRepo.read(entry)).thenAnswer((_) async => model);
      when(() => backupRepo.import(model)).thenAnswer((_) async {
        imported = true; // çalma listeleri tablosu yeniden kuruldu
      });
      when(() => libraryRepo.rescan()).thenAnswer((_) async {});

      final ok = await auto.restore(entry);
      expect(ok, isTrue);

      // Uygulama yeniden başlatmadan liste yedekteki hale döner:
      expect(playlists.playlists.length, 1);
      expect(playlists.playlists.first.name, 'Yedekten');
    });
  });
}