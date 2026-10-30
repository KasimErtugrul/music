// Gün 10 testi: prefs anahtar geçiş fonksiyonu (SettingsKeyMigration).
//
// Geçiş haritası bugün boştur (Gün 10 baseline taraması: ac5b892'deki
// tüm anahtar dizgeleri bugünkü SettingsPersistence değerleriyle aynı);
// bu testler sözleşmeyi sentetik haritalarla pinler — ilk gerçek yeniden
// adlandırmada davranış garanti altındadır. İki uygulama noktası ayrı
// ayrı sınanır: (1) main() açılışındaki disk geçişi, (2) yedek içe
// aktarmada eski anahtar adının geçerli anahtara eşlenmesi.
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/settings/settings_key_migration.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/datasources/backup_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('geçiş haritası bugün boştur (yeniden adlandırma yapılmadı)', () {
    // Bilinçli pin: haritaya girdi eklenirse bu test ve tel-format pin
    // testi (settings_backup_keys_test) birlikte güncellenmelidir.
    expect(SettingsKeyMigration.legacyKeys, isEmpty);
  });

  group('migrate — main() açılışındaki disk geçişi (Gün 10)', () {
    test('eski anahtar yeni anahtara taşınır ve silinir', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'old_history': '["ada"]',
      });
      final prefs = await SharedPreferences.getInstance();

      await SettingsKeyMigration.migrate(
        prefs,
        legacyKeys: const {'old_history': SettingsPersistence.searchHistory},
      );

      expect(prefs.getString(SettingsPersistence.searchHistory), '["ada"]');
      expect(prefs.containsKey('old_history'), isFalse);
    });

    test('değer tipi korunur (bool/int/double/StringList)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'old_bool': true,
        'old_int': 42,
        'old_double': 1.5,
        'old_list': <String>['a'],
      });
      final prefs = await SharedPreferences.getInstance();

      await SettingsKeyMigration.migrate(
        prefs,
        legacyKeys: const {
          'old_bool': 'new_bool',
          'old_int': 'new_int',
          'old_double': 'new_double',
          'old_list': 'new_list',
        },
      );

      expect(prefs.getBool('new_bool'), isTrue);
      expect(prefs.getInt('new_int'), 42);
      expect(prefs.getDouble('new_double'), 1.5);
      expect(prefs.getStringList('new_list'), <String>['a']);
      expect(prefs.containsKey('old_bool'), isFalse);
      expect(prefs.containsKey('old_int'), isFalse);
      expect(prefs.containsKey('old_double'), isFalse);
      expect(prefs.containsKey('old_list'), isFalse);
    });

    test('geçerli anahtar zaten varsa değer korunur; eski yalnız silinir',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'old_history': '["eski"]',
        SettingsPersistence.searchHistory: '["mevcut"]',
      });
      final prefs = await SharedPreferences.getInstance();

      await SettingsKeyMigration.migrate(
        prefs,
        legacyKeys: const {'old_history': SettingsPersistence.searchHistory},
      );

      expect(prefs.getString(SettingsPersistence.searchHistory), '["mevcut"]');
      expect(prefs.containsKey('old_history'), isFalse);
    });

    test('boş haritayla çağrı no-optur ve fırlatmaz (üretim varsayılanı)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsPersistence.searchHistory: '["ada"]',
      });
      final prefs = await SharedPreferences.getInstance();

      await SettingsKeyMigration.migrate(prefs);

      expect(prefs.getString(SettingsPersistence.searchHistory), '["ada"]');
    });
  });

  group('applyBackedUpSettings — yedek içe aktarma eşlemesi (Gün 10)', () {
    test('yedekteki eski anahtar, geçerli anahtara uygulanır', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await BackupDatasource.applyBackedUpSettings(
        prefs,
        <String, dynamic>{'old_history': '["yedekten"]'},
        legacyKeys: const {'old_history': SettingsPersistence.searchHistory},
      );

      expect(
        prefs.getString(SettingsPersistence.searchHistory),
        '["yedekten"]',
      );
    });

    test('geçerli ad yedekte zaten varsa o kazanır; eski ad sorgulanmaz',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await BackupDatasource.applyBackedUpSettings(
        prefs,
        <String, dynamic>{
          'old_history': '["eski"]',
          SettingsPersistence.searchHistory: '["yeni"]',
        },
        legacyKeys: const {'old_history': SettingsPersistence.searchHistory},
      );

      expect(
        prefs.getString(SettingsPersistence.searchHistory),
        '["yeni"]',
      );
    });
  });
}