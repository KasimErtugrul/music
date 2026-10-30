// Gün 1 testi: yedek anahtar bütünlüğü.
//
// Amaç: prefs'e gerçekten yazan HER setter sahte SharedPreferences ile
// çalıştırılır; ardından prefs.getKeys() içindeki her anahtar ya
// SettingsPersistence.backupKeys içinde ya da bilinçli olarak yedeklenmeyen
// (notBackedUpKeys) listede olmalıdır. Yeni bir prefs anahtarı yazan kod
// listeye eklenmezse bu test kırılır — böylece kalıcı kullanıcı verisi
// sessizce yedek dışında kalamaz.
//
// Neden gerçek WidgetsFlutterBinding (testWidgets DEĞİL): SettingsController
// (Get.updateLocale → forceAppUpdate) ve ThemeController zincirleri
// "await endOfFrame" ile biten performReassemble çağırır. flutter_test'in
// AutomatedTestWidgetsFlutterBinding'i frame pompalanmadıkça bu Future'ı
// asla tamamlamaz (düz test() bölgesinde de inTest assertion'ı kırılır).
// Gerçek binding ile warm-up frame gerçek zero-timer'larla koşar ve zincir
// doğal biçimde tamamlanır. ThemeController'ın dakikalık zamanlayıcısı yine
// dispose() ile kapatılır (temizlik).
//
// Dışa/içe aktarma mantığı da (BackupDatasource.collectBackedUpSettings /
// applyBackedUpSettings) burada test edilir: bilinmeyen anahtar yok sayılır,
// desteklenmeyen değer tiplerinde çökme olmaz, eksik anahtarlar mevcut
// değeri korur (eski yedeklerle geriye dönük uyum).

import 'dart:convert';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/datasources/backup_datasource.dart';
import 'package:resonance/data/datasources/equalizer_datasource.dart';
import 'package:resonance/data/datasources/home_widget_datasource.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/data/repositories/home_widget_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

class _MockHomeWidgetRepository extends Mock implements HomeWidgetRepository {}

class _MockHomeWidgetDatasource extends Mock implements HomeWidgetDatasource {}

class _MockPlayerController extends Mock implements PlayerController {}

class _MockAudioEffectsDatasource extends Mock
    implements AudioEffectsDatasource {}

class _MockEqualizerDatasource extends Mock implements EqualizerDatasource {}

class _MockAutoBackupRepository extends Mock implements AutoBackupRepository {}

class _MockBackupRepository extends Mock implements BackupRepository {}

/// Microtask ve fire-and-forget zincirlerinin (updateLocale'in
/// forceAppUpdate'i dahil) boşalmasını bekler.
Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

/// Tüm gerçek yazıcı bileşenlerini kurar ve setter'larını bir kez çalıştırır.
/// Dönen ThemeController, test sonunda dispose EDİLMELİDİR
/// (periyodik zamanlayıcıyı kapatmak için).
Future<ThemeController> driveAllWriters(SharedPreferences prefs) async {
  // 1) PreferencesController → playback_settings + library_settings JSON'ları.
  final prefCtrl = Get.put<PreferencesController>(
    PreferencesController(PreferencesRepositoryImpl(prefs)),
  );
  await prefCtrl.reload();
  prefCtrl.setSeekInterval(30);
  prefCtrl.setAutoResume(true);
  prefCtrl.setSpeed(1.25);
  prefCtrl.setPitch(0.5);
  prefCtrl.setReplayGain(true);
  prefCtrl.setSkipSilence(true);
  prefCtrl.setPauseOnHeadphone(true);
  prefCtrl.setDefaultShuffle(true);
  prefCtrl.setDefaultRepeat(2);
  prefCtrl.setScanOnStartup(true);
  prefCtrl.setMinDuration(60);

  // 2) SettingsController → language_code (+ yerel güncellemesi).
  final settingsCtrl = Get.put<SettingsController>(
    SettingsController(SettingsRepositoryImpl(prefs)),
  );
  await settingsCtrl.reload();
  await _flush(); // updateLocale → forceAppUpdate zinciri biter
  await settingsCtrl.setLanguage('tr');
  await _flush();

  // 3) ThemeController → active_theme_settings JSON'u.
  final themeCtrl = Get.put<ThemeController>(
    ThemeController(
      ThemeRepositoryImpl(prefs),
      const Stream<MediaItem?>.empty(),
      _MockLibraryRepository(),
    ),
  );
  await _flush(); // _loadActive mikro görevleri biter
  themeCtrl.setSeed(const Color(0xFF123456));
  await _flush(); // fire-and-forget saveActiveTheme tamamlanır

  // 4) EqualizerRepository → equalizer_enabled / gains / loudness.
  final effects = _MockAudioEffectsDatasource();
  when(() => effects.setEnabled(any())).thenAnswer((_) async {});
  when(() => effects.setLoudnessEnabled(any())).thenAnswer((_) async {});
  when(() => effects.setLoudnessGain(any())).thenAnswer((_) async {});
  final eqRepo = EqualizerRepositoryImpl(
    effects,
    _MockEqualizerDatasource(),
    prefs,
  );
  await eqRepo.setEnabled(true);
  await eqRepo.saveGains(const [1.5, -2.0, 0.5]);
  await eqRepo.saveLoudness(2.5);

  // 5) Widget şeffaflığı → widget_transparent.
  final player = _MockPlayerController();
  when(() => player.currentItem).thenReturn(Rxn<MediaItem>());
  when(() => player.isPlaying).thenReturn(false.obs);
  final widgetRepo = _MockHomeWidgetRepository();
  when(
    () => widgetRepo.updateWidget(
      title: any(named: 'title'),
      artist: any(named: 'artist'),
      isPlaying: any(named: 'isPlaying'),
      isTransparent: any(named: 'isTransparent'),
    ),
  ).thenAnswer((_) async {});
  final widgetDs = _MockHomeWidgetDatasource();
  when(() => widgetDs.saveArtwork(any())).thenAnswer((_) async {});
  final widgetCtrl = Get.put<HomeWidgetController>(
    HomeWidgetController(
      widgetRepo,
      widgetDs,
      player,
      _MockLibraryRepository(),
      prefs,
    ),
  );
  await widgetCtrl.setTransparency(true);

  // 6) Arama geçmişi → search_history.
  final searchCtrl = Get.put<AppSearchController>(
    AppSearchController(_MockLibraryRepository()),
  );
  await searchCtrl.commitSearch('metallica');

  // 7) Otomatik yedekleme tercihleri → settings_auto_backup_*.
  final autoRepo = _MockAutoBackupRepository();
  when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
  final autoCtrl = Get.put<AutoBackupController>(
    AutoBackupController(
      autoRepo: autoRepo,
      backupRepo: _MockBackupRepository(),
      libraryRepo: _MockLibraryRepository(),
      prefs: prefs,
    ),
  );
  await autoCtrl.setEnabled(false);
  await autoCtrl.setFrequency(AutoBackupFrequency.weekly);
  await autoCtrl.setKeepCount(5);

  return themeCtrl;
}

void main() {
  // Not: TestWidgetsFlutterBinding.ensureInitialized DEĞİL — açıklama dosya
  // başında. Gerçek binding, updateLocale'in endOfFrame zincirini tamamlar.
  WidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(false);
    registerFallbackValue(0.0);
    registerFallbackValue('');
    registerFallbackValue(Uint8List(0));
  });

  late SharedPreferences prefs;

  setUp(() async {
    Get.testMode = true;
    // changeThemeMode / updateLocale kayıtlı kök controller olmadan
    // çağrılırsa Get.find patlar; testte kaydederek güvenli hale getiriyoruz.
    Get.put<GetMaterialController>(GetMaterialController());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    // SearchController gibi prefs'i Get.find ile alan bileşenler için.
    Get.put<SharedPreferences>(prefs);
  });

  tearDown(() {
    Get.reset();
  });

  group('yedek anahtar bütünlüğü', () {
    test(
      'backupKeys içinde yinelenen veya hariç listeyle çakışan anahtar yok',
      () {
        expect(
          SettingsPersistence.backupKeys.toSet().length,
          SettingsPersistence.backupKeys.length,
          reason: 'backupKeys içinde yinelenen anahtar var',
        );
        expect(
          SettingsPersistence.backupKeys.toSet().intersection(
            SettingsPersistence.notBackedUpKeys.toSet(),
          ),
          isEmpty,
          reason: 'Bir anahtar hem yedekleniyor hem hariç listede olamaz',
        );
      },
    );

    test(
      'anahtar dizgeleri tel formatına sabitlenmiştir (eski yedeklerle uyum)',
      () {
        // Bu dizgeler yedek dosyasında anahtar olarak durur; yeniden adlandırma
        // eski yedeklerin geri yüklenmesini kırar. Gün 10'da geçiş fonksiyonu
        // (SettingsKeyMigration) kuruldu: bir yeniden adlandırma artık yalnız
        // legacyKeys haritasına tek satır eklenerek + bu pin testi
        // güncellenerek yapılır (disk ve yedek yolu otomatik geçer).
        expect(SettingsPersistence.languageCode, 'language_code');
        expect(SettingsPersistence.playbackSettings, 'playback_settings');
        expect(SettingsPersistence.librarySettings, 'library_settings');
        expect(
          SettingsPersistence.activeThemeSettings,
          'active_theme_settings',
        );
        expect(SettingsPersistence.equalizerEnabled, 'equalizer_enabled');
        expect(SettingsPersistence.equalizerGains, 'equalizer_gains');
        expect(SettingsPersistence.equalizerLoudness, 'equalizer_loudness');
        expect(SettingsPersistence.widgetTransparent, 'widget_transparent');
        expect(SettingsPersistence.searchHistory, 'search_history');
        expect(
          SettingsPersistence.autoBackupEnabled,
          'settings_auto_backup_enabled',
        );
        expect(
          SettingsPersistence.autoBackupFrequency,
          'settings_auto_backup_frequency',
        );
        expect(SettingsPersistence.autoBackupKeep, 'settings_auto_backup_keep');
        expect(SettingsPersistence.lastBackupAt, 'last_backup_at');
        expect(SettingsPersistence.autoBackupLast, 'settings_auto_backup_last');
      },
    );

    test('prefs’e yazılan her anahtar yedek listelerinde tanımlıdır', () async {
      final themeCtrl = await driveAllWriters(prefs);
      await _flush();

      final unknown =
          prefs
              .getKeys()
              .where(
                (k) =>
                    !SettingsPersistence.backupKeys.contains(k) &&
                    !SettingsPersistence.notBackedUpKeys.contains(k),
              )
              .toList()
            ..sort();

      themeCtrl.dispose();
      expect(
        unknown,
        isEmpty,
        reason:
            'Şu anahtarlar SettingsPersistence listelerinde tanımlı değil; '
            'yazan kodu SettingsPersistence’a ekleyin: $unknown',
      );
    });

    test('yedek, yedeklenmesi beklenen tüm anahtarları içerir', () async {
      final themeCtrl = await driveAllWriters(prefs);
      await _flush();

      final collected = BackupDatasource.collectBackedUpSettings(prefs);
      themeCtrl.dispose();

      for (final key in SettingsPersistence.backupKeys) {
        expect(collected.containsKey(key), isTrue, reason: '$key yedekte yok');
      }
      // Hariç listedeki anahtarlar yedeğe girmez.
      for (final key in SettingsPersistence.notBackedUpKeys) {
        expect(
          collected.containsKey(key),
          isFalse,
          reason: '$key yedeklenmemeli',
        );
      }
    });

    test('collect, listede olmayan anahtarları yedeğe almaz', () async {
      final themeCtrl = await driveAllWriters(prefs);
      await _flush();
      // BackupController/AutoBackupController zaman damgalarını simüle et;
      // bunlar notBackedUpKeys içinde tanımlıdır.
      await prefs.setInt(SettingsPersistence.lastBackupAt, 42);
      await prefs.setInt(SettingsPersistence.autoBackupLast, 43);
      await prefs.setString('bazı_bilinmeyen_anahtar', 'x');

      final collected = BackupDatasource.collectBackedUpSettings(prefs);
      themeCtrl.dispose();

      expect(collected.containsKey(SettingsPersistence.lastBackupAt), isFalse);
      expect(
        collected.containsKey(SettingsPersistence.autoBackupLast),
        isFalse,
      );
      expect(collected.containsKey('bazı_bilinmeyen_anahtar'), isFalse);
      expect(collected[SettingsPersistence.playbackSettings], isA<String>());
    });
  });

  group('tip güvenli içe aktarma', () {
    test('bilinmeyen anahtarları yok sayar, bozuk tipte çökmez, eksik anahtara dokunmaz', () async {
      await prefs.setString('mevcut_değer', 'dokunulmaz');

      final raw = <String, dynamic>{
        'bilinmeyen': 'yok sayılmalı',
        SettingsPersistence.equalizerEnabled: true,
        SettingsPersistence.equalizerLoudness: 3.5,
        SettingsPersistence.autoBackupKeep: 5,
        SettingsPersistence.searchHistory: <String>['a', 'b'],
        // Desteklenmeyen değer tipi (List<int>): atlanmalı, çökmemeli.
        SettingsPersistence.widgetTransparent: <int>[1, 2],
      };

      await BackupDatasource.applyBackedUpSettings(prefs, raw);

      expect(prefs.containsKey('bilinmeyen'), isFalse);
      expect(prefs.getString('mevcut_değer'), 'dokunulmaz');
      expect(prefs.getBool(SettingsPersistence.equalizerEnabled), isTrue);
      expect(prefs.getDouble(SettingsPersistence.equalizerLoudness), 3.5);
      expect(prefs.getInt(SettingsPersistence.autoBackupKeep), 5);
      expect(prefs.getStringList(SettingsPersistence.searchHistory), <String>[
        'a',
        'b',
      ]);
      expect(prefs.containsKey(SettingsPersistence.widgetTransparent), isFalse);
    });

    test('JSON gidiş-dönüşü tüm değer tiplerini korur', () async {
      final themeCtrl = await driveAllWriters(prefs);
      await _flush();

      final collected = BackupDatasource.collectBackedUpSettings(prefs);
      themeCtrl.dispose();

      final model = BackupModel(
        settings: collected,
        playlists: const [],
        favorites: const [],
        customThemes: const [],
        equalizerPresets: const [],
      );
      final restored = BackupModel.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>,
      );

      // "Temiz prefs" simülasyonu: mevcut anahtarları sil, yalnızca yedekten
      // gelenler yazılsın (SharedPreferences.getInstance örneği cache'lidir;
      // yeniden setMockInitialValues aynı örneği döndürdüğü için silme yolu
      // kullanılır).
      for (final key in prefs.getKeys().toList()) {
        await prefs.remove(key);
      }
      await BackupDatasource.applyBackedUpSettings(prefs, restored.settings);

      expect(prefs.getString(SettingsPersistence.languageCode), 'tr');
      // playback JSON'u gidiş-dönüşte alan değerlerini korur.
      final playback = jsonDecode(
        prefs.getString(SettingsPersistence.playbackSettings)!,
      ) as Map<String, dynamic>;
      expect(playback['seekIntervalSeconds'], 30);
      expect(playback['speed'], 1.25);
      expect(playback['defaultRepeat'], 2);
      final library = jsonDecode(
        prefs.getString(SettingsPersistence.librarySettings)!,
      ) as Map<String, dynamic>;
      expect(library['minDurationSeconds'], 60);
      expect(prefs.getBool(SettingsPersistence.equalizerEnabled), isTrue);
      expect(prefs.getDouble(SettingsPersistence.equalizerLoudness), 2.5);
      expect(prefs.getBool(SettingsPersistence.widgetTransparent), isTrue);
      expect(
        prefs.getString(SettingsPersistence.searchHistory),
        jsonEncode(<String>['metallica']),
      );
      expect(prefs.getBool(SettingsPersistence.autoBackupEnabled), isFalse);
      expect(
        prefs.getString(SettingsPersistence.autoBackupFrequency),
        'weekly',
      );
      expect(prefs.getInt(SettingsPersistence.autoBackupKeep), 5);
      // Tema JSON'u gidiş-dönüşte birebir aynı kalmalı.
      expect(
        jsonDecode(prefs.getString(SettingsPersistence.activeThemeSettings)!)
            as Map<String, dynamic>,
        jsonDecode(collected[SettingsPersistence.activeThemeSettings] as String)
            as Map<String, dynamic>,
      );
    });

    test('içe aktarma sonrası PreferencesController.reload() canlı durumu yedekteki hale döndürür', () async {
      final prefCtrl = Get.put<PreferencesController>(
        PreferencesController(PreferencesRepositoryImpl(prefs)),
      );
      await prefCtrl.reload();
      prefCtrl.setSeekInterval(30);

      final collected = BackupDatasource.collectBackedUpSettings(prefs);

      // Kullanıcı sonra başka bir değere değiştirsin.
      prefCtrl.setSeekInterval(15);
      expect(prefCtrl.playback.value.seekIntervalSeconds, 15);

      // Yedek geri yüklenir ve canlı controller yeniden okur.
      await BackupDatasource.applyBackedUpSettings(prefs, collected);
      await prefCtrl.reload();
      expect(prefCtrl.playback.value.seekIntervalSeconds, 30);
    });

    test('içe aktarma sonrası ThemeController.reload() temayı yedekteki hale döndürür', () async {
      final themeCtrl = Get.put<ThemeController>(
        ThemeController(
          ThemeRepositoryImpl(prefs),
          const Stream<MediaItem?>.empty(),
          _MockLibraryRepository(),
        ),
      );
      await _flush();

      themeCtrl.setSeed(const Color(0xFF111111));
      await _flush();
      final collected = BackupDatasource.collectBackedUpSettings(prefs);

      themeCtrl.setSeed(const Color(0xFF222222));
      await _flush();
      expect(themeCtrl.settings.value.seedColor, const Color(0xFF222222));

      await BackupDatasource.applyBackedUpSettings(prefs, collected);
      await themeCtrl.reload();
      themeCtrl.dispose();
      expect(themeCtrl.settings.value.seedColor, const Color(0xFF111111));
    });
  });
}
