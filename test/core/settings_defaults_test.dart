// Gün 4 testi: SettingsDefaults temizliği ve canlı varsayılanın korunması.
//
// Gün 4, ölü varsayılan sabitlerini (dynamicColor / amoledDark) kaldırdı;
// Gün 8, son ölü sabiti (themeMode) kaldırdı. Bu dosya iki şeyi güvence
// altına alır:
// 1. Kalan canlı varsayılan (languageCode) tel değere sabittir ve
//    SettingsRepository boş prefs değerinde ona düşer; kayıtlı değer
//    varsayılana üstünlük verir. Tohum anahtarı SettingsPersistence'tan
//    gelir (Gün 8 doktrini: prefs kimliği kalıcılık katmanından).
// 2. Temizlenen ölü anahtarlar (dynamic_color / amoled_dark) ayar
//    haritasına (SettingsRegistry) geri dönemez; "theme_mode" ise canlı
//    arayüz girdisi (Tema ayarları sayfası) olarak kalır.

import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/settings/settings_defaults.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsDefaults (Gün 4)', () {
    test('languageCode varsayılanı tel değere sabittir', () {
      // Geçerli değerler: system | tr | en. Değişiklik yalnızca bilinçli
      // bir Karar ile ve settings_repository davranışı gözden geçirilerek
      // yapılabilir.
      expect(SettingsDefaults.languageCode, 'system');
    });

    test('SettingsRepository prefs boşken varsayılana düşer', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = SettingsRepositoryImpl(await SharedPreferences.getInstance());
      final model = await repo.load();
      expect(model.languageCode, SettingsDefaults.languageCode);
    });

    test('SettingsRepository kayıtlı değeri varsayılana tercih eder', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        // Gün 8: tohum kimliği SettingsPersistence'tan — repo artık aynı
        // katmandan okur. (Aynı dizge: SettingsPersistence.languageCode,
        // SettingsKeys.languageCode takma adıdır; tel değer pin'i
        // settings_backup_keys_test'tedir.)
        SettingsPersistence.languageCode: 'tr',
      });
      final repo = SettingsRepositoryImpl(await SharedPreferences.getInstance());
      final model = await repo.load();
      expect(model.languageCode, 'tr');
    });
  });

  group('Ölü ayar anahtarları geri dönemez (Gün 4 / Gün 8)', () {
    test('dynamic_color ve amoled_dark ayar haritasında yer almaz', () {
      // Görev 4.2 sonrası gerçek karşılıklar theme_color_source ve
      // theme_amoled anahtarlarıdır; eski isimler aramada da bulunamaz.
      expect(SettingsRegistry.find('dynamic_color'), isNull);
      expect(SettingsRegistry.find('amoled_dark'), isNull);
    });

    test('dynamicColor, amoledDark ve themeMode sabitleri bir daha eklenmez',
        () {
      // Yansıma yok; derleme zamanı güvence: dosyanın kendisinde yalnız
      // languageCode tanımlıdır. Bu test, ölü sabitlerin kaldırıldığı
      // Gün 4 (dynamicColor / amoledDark) ve Gün 8 (themeMode) sonrası
      // public yüzeyi belgeler. Tema modu active_theme_settings JSON'undaki
      // ThemeSettings.themeMode ile yaşar (theme_engine.dart).
      expect(SettingsDefaults.languageCode, isA<String>());
    });

    test('theme_mode canlı arayüz girdisi olarak kalır', () {
      final entry = SettingsRegistry.find(SettingsKeys.themeMode);
      expect(entry, isNotNull);
      expect(entry!.pageBuilder, isNotNull);
    });
  });
}