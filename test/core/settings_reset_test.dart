// Gün 6: "Tüm ayarları sıfırla" akışı testleri.
//
// Kapsam:
// * PreferencesRepositoryImpl.resetAll artık SettingsPersistence.backupKeys
//   listesinin TAMAMINI kaldırır; zaman damgası anahtarları korunur.
// * AppSearchController.reload() ve AutoBackupController.reload() kalıcı
//   tercihleri yeniden okur (anahtar yokluğu = fabrika varsayılanı).
// * PreferencesController.resetAll diski temizler, kendi Rx durumunu
//   sıfırlar ve kayıtlı canlı controller'ları yeniden yükler.
//
// Gün 11: resetAll içindeki canlı tazeleme zinciri Gün 7'nin tek doğruluk
// kaynağına (live_settings_reload.dart) bağlandı; Gün 6'dan kalma özel
// kopya silindi. Testler değişmedi — aynı davranış artık paylaşılan zincir
// üzerinden pinleniyor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLibraryRepo extends Mock implements LibraryRepository {}

class _MockAutoRepo extends Mock implements AutoBackupRepository {}

class _MockBackupRepo extends Mock implements BackupRepository {}

/// SettingsController için sahte repo: her yüklemede varsayılan ('system')
/// döner; yazım yok sayılır. Böylece resetAll -> reload zinciri 'tr'
/// tercihini 'system'e döndürmesi test edilebilir.
class _FakeSettingsRepo implements SettingsRepository {
  @override
  Future<AppSettingsModel> load() async =>
      const AppSettingsModel(languageCode: 'system');

  @override
  Future<void> setString(String key, String value) async {}
}

// Neden gerçek WidgetsFlutterBinding (testWidgets DEĞİL): Gün 1 testindeki
// belgelenmiş düzende aynen — SettingsController.reload zinciri
// Get.updateLocale → forceAppUpdate ile "await endOfFrame"te biten bir
// performReassemble çağırır; flutter_test'in test binding'i frame
// pompalanmadıkça bu Future'ı asla tamamlamaz. Gerçek binding ile warm-up
// frame gerçek zero-timer'larla koşar ve zincir doğal biçimde tamamlanır.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late _MockLibraryRepo libraryRepo;
  late _MockAutoRepo autoRepo;
  late _MockBackupRepo backupRepo;

  setUp(() {
    libraryRepo = _MockLibraryRepo();
    autoRepo = _MockAutoRepo();
    backupRepo = _MockBackupRepo();
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
  });

  tearDown(() async {
    Get.reset();
  });

  /// Microtask ve fire-and-forget zincirlerinin (updateLocale'in
  /// forceAppUpdate'i dahil) boşalmasını bekler (Gün 1 düzeniyle aynı).
  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  /// Tüm yedeklenen ayar anahtarları gerçekçi değerlerle yüklü prefs.
  /// Zaman damgaları da yüklüdür: korunmaları ayrıca test edilir.
  Future<SharedPreferences> seededPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SettingsPersistence.languageCode: 'tr',
      SettingsPersistence.playbackSettings: '{"seekIntervalSeconds":30}',
      SettingsPersistence.librarySettings: '{"scanOnStartup":false}',
      SettingsPersistence.activeThemeSettings: '{"themeSource":"seed"}',
      SettingsPersistence.equalizerEnabled: true,
      SettingsPersistence.equalizerGains: '[1,2]',
      SettingsPersistence.equalizerLoudness: 3.0,
      SettingsPersistence.widgetTransparent: true,
      SettingsPersistence.searchHistory: '["ada","beat"]',
      SettingsPersistence.autoBackupEnabled: false,
      SettingsPersistence.autoBackupFrequency: 'weekly',
      SettingsPersistence.autoBackupKeep: 3,
      SettingsPersistence.lastBackupAt: 1700000000000,
      SettingsPersistence.autoBackupLast: 1700000000000,
    });
    return SharedPreferences.getInstance();
  }

  group('PreferencesRepositoryImpl.resetAll (Gün 6)', () {
    test('backupKeys listesinin tamamını kaldırır', () async {
      final prefs = await seededPrefs();
      final repo = PreferencesRepositoryImpl(prefs);

      await repo.resetAll();

      for (final key in SettingsPersistence.backupKeys) {
        expect(prefs.get(key), isNull, reason: '$key sıfırlanmalıydı');
      }
    });

    test('zaman damgası anahtarları (notBackedUpKeys) korunur', () async {
      final prefs = await seededPrefs();
      final repo = PreferencesRepositoryImpl(prefs);

      await repo.resetAll();

      expect(prefs.getInt(SettingsPersistence.lastBackupAt), 1700000000000);
      expect(prefs.getInt(SettingsPersistence.autoBackupLast), 1700000000000);
    });

    test('reset sonrası playback/library yüklemesi varsayılana düşer',
        () async {
      final prefs = await seededPrefs();
      final repo = PreferencesRepositoryImpl(prefs);

      await repo.resetAll();

      final playback = await repo.loadPlayback();
      final library = await repo.loadLibrary();
      expect(playback.seekIntervalSeconds, 10);
      expect(library.scanOnStartup, isTrue);
    });
  });

  group('AppSearchController.reload (Gün 6)', () {
    test('geçmişi yeniden okur; anahtar yoksa boşalır ve geri yazmaz',
        () async {
      final prefs = await seededPrefs();
      Get.put<SharedPreferences>(prefs);
      final c = Get.put<AppSearchController>(
        AppSearchController(libraryRepo),
      );

      expect(c.searchHistory, <String>['ada', 'beat']);

      await prefs.remove(SettingsPersistence.searchHistory);
      await c.reload();

      expect(c.searchHistory, isEmpty);
      // reload yalnız okur: silinmiş anahtar boş kayıtla geri yazılmaz.
      expect(prefs.getString(SettingsPersistence.searchHistory), isNull);
    });
  });

  group('AutoBackupController.reload (Gün 6)', () {
    test('kaldırılan tercihler sonrası fabrika değerlerine döner', () async {
      final prefs = await seededPrefs();
      final c = Get.put<AutoBackupController>(
        AutoBackupController(
          autoRepo: autoRepo,
          backupRepo: backupRepo,
          libraryRepo: libraryRepo,
          prefs: prefs,
        ),
      );

      // Tohumlanmış prefs: kapalı, haftalık, 3 yedek, son yedek var.
      expect(c.enabled.value, isFalse);
      expect(c.frequency.value, AutoBackupFrequency.weekly);
      expect(c.keepCount.value, 3);
      expect(c.lastRunAt.value, isNotNull);

      await prefs.remove(SettingsPersistence.autoBackupEnabled);
      await prefs.remove(SettingsPersistence.autoBackupFrequency);
      await prefs.remove(SettingsPersistence.autoBackupKeep);
      await prefs.remove(SettingsPersistence.autoBackupLast);
      await c.reload();

      expect(c.enabled.value, isTrue);
      expect(c.frequency.value, AutoBackupFrequency.daily);
      expect(c.keepCount.value, AutoBackupController.defaultKeepCount);
      expect(c.lastRunAt.value, isNull);
    });
  });

  group('PreferencesController.resetAll orkestrasyonu (Gün 6)', () {
    test('diski temizler, kendi Rx durumunu sıfırlar, canlı controller\u2019ları'
        ' yeniden yükler', () async {
      final prefs = await seededPrefs();
      Get.put<SharedPreferences>(prefs);

      final prefsCtrl = Get.put<PreferencesController>(
        PreferencesController(PreferencesRepositoryImpl(prefs)),
      );
      await prefsCtrl.ready;

      // Canlı durumda varsayımdan farklı değerler:
      prefsCtrl.playback.value =
          prefsCtrl.playback.value.copyWith(seekIntervalSeconds: 30);
      prefsCtrl.library.value =
          prefsCtrl.library.value.copyWith(scanOnStartup: false);

      final settingsCtrl = Get.put<SettingsController>(
        SettingsController(_FakeSettingsRepo()),
      );
      // onInit yüklemesi mikro-görevde tamamlanır:
      await Future<void>.delayed(Duration.zero);
      settingsCtrl.settings.value =
          settingsCtrl.settings.value!.copyWith(languageCode: 'tr');

      final searchCtrl = Get.put<AppSearchController>(
        AppSearchController(libraryRepo),
      );
      final autoCtrl = Get.put<AutoBackupController>(
        AutoBackupController(
          autoRepo: autoRepo,
          backupRepo: backupRepo,
          libraryRepo: libraryRepo,
          prefs: prefs,
        ),
      );

      await prefsCtrl.resetAll();
      await flush(); // updateLocale → forceAppUpdate zinciri biter

      // 1) Disk temizlendi (zaman damgaları hariç — ayrı testte).
      for (final key in SettingsPersistence.backupKeys) {
        expect(prefs.get(key), isNull, reason: '$key sıfırlanmalıydı');
      }

      // 2) Kendi Rx durumu fabrika değerinde.
      expect(prefsCtrl.playback.value.seekIntervalSeconds, 10);
      expect(prefsCtrl.library.value.scanOnStartup, isTrue);

      // 3) Canlı controller'lar yeniden yüklendi (kayıtlı olanlar):
      //    - SettingsController yeniden okudu -> 'system' döndü.
      expect(settingsCtrl.settings.value!.languageCode, 'system');
      //    - AppSearchController geçmişi boşalttı.
      expect(searchCtrl.searchHistory, isEmpty);
      //    - AutoBackupController varsayılanlara döndü.
      expect(autoCtrl.enabled.value, isTrue);
      expect(autoCtrl.frequency.value, AutoBackupFrequency.daily);
      expect(autoCtrl.keepCount.value, AutoBackupController.defaultKeepCount);
    });

    test('kayıtlı olmayan canlı controller\u2019lar sessizce atlanır', () async {
      // Yalnız PreferencesController kayıtlı; Theme/Settings/Equalizer/
      // HomeWidget/AppSearch/AutoBackup yok. resetAll hata fırlatmamalı.
      final prefs = await seededPrefs();
      final prefsCtrl = Get.put<PreferencesController>(
        PreferencesController(PreferencesRepositoryImpl(prefs)),
      );
      await prefsCtrl.ready;

      await prefsCtrl.resetAll();

      expect(prefs.get(SettingsPersistence.languageCode), isNull);
      expect(prefs.get(SettingsPersistence.playbackSettings), isNull);
    });
  });
}