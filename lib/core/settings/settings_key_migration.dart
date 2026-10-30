// Gün 10: prefs anahtar geçiş fonksiyonu (planın «anahtar geçiş» kalemi).
//
// Neden: bir kalıcılık anahtarı yeniden adlandırıldığında iki veri kaybı
// doğar — (1) kullanıcının diskteki mevcut tercihi eski anahtar altında
// kalır, (2) eski yedek dosyaları yeni anahtar adını içermez; her iki yol
// da ayarı sessizce varsayılana döndürür. settings_backup_keys_test'teki
// tel-format pin'inin («Değişiklik yalnızca geçiş fonksiyonuyla (Gün 10)
// birlikte yapılabilir») ve Gün 5 ham-anahtar yasağının («ham anahtar,
// Gün 10'daki anahtar geçiş fonksiyonundan sessizce kaçar») işaret ettiği
// güvenlik ağı budur: yeniden adlandırma artık tek satırlık harita
// girdisi + pin testinin güncellenmesidir.
//
// Bugün harita BOŞTUR ve bu bilinçlidir: taban commit'in (ac5b892) lib/
// taramasındaki tüm prefs anahtar dizgeleri bugünkü SettingsPersistence
// değerleriyle birebir aynı çıktı (Gün 10 denetimi); kozmetik bir
// yeniden adlandırma ayrıca riskliydir — 'widget_transparent' native
// Android sözleşmesi (MusicWidgetProvider.kt) ile eşleşir, dokunulmaz.
// İşlev iki noktadan CANLI çağrılır: main() açılışındaki disk geçişi ve
// BackupDatasource.applyBackedUpSettings içindeki yedek içe aktarma
// eşlemesi. Harita boşken ikisi de no-op'tur; ilk gerçek yeniden
// adlandırmada davranış devreye girer.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class SettingsKeyMigration {
  /// Eski anahtar → geçerli anahtar. Bir yeniden adlandırma yapıldığında
  /// buraya tek satır eklenir; tel-format pin testi
  /// (settings_backup_keys_test) ve bu sınıfın belgesi birlikte
  /// güncellenir.
  static const Map<String, String> legacyKeys = <String, String>{};

  /// Diskteki eski anahtarları geçerli anahtarlara taşır (main() açılışı).
  ///
  /// * Eski anahtar yok → dokunulmaz.
  /// * Geçerli anahtar zaten var → geçerli değer kazanır, eski anahtar
  ///   silinir (çift yazım tekilleşir).
  /// * Değer tipi korunur (`String`/`bool`/`int`/`double`/`List<String>`);
  ///   desteklenmeyen tipte eski anahtar VERİ KAYBI OLMASIN diye
  ///   dokunulmadan bırakılır.
  /// * Tek bir girdinin hatası kalanları durdurmaz; işlev hiçbir koşulda
  ///   fırlatmaz (açılış akışını engellemez, main'in hata kapısına
  ///   düşmez).
  ///
  /// [legacyKeys] test enjeksiyonu içindir (AutoBackupController'ın
  /// `now` enjeksiyonuyla aynı düzen); üretim çağrıları varsayılan
  /// haritayı kullanır.
  static Future<void> migrate(
    SharedPreferences prefs, {
    Map<String, String> legacyKeys = SettingsKeyMigration.legacyKeys,
  }) async {
    for (final entry in legacyKeys.entries) {
      try {
        final legacy = entry.key;
        final current = entry.value;
        if (legacy == current || !prefs.containsKey(legacy)) continue;
        final value = prefs.get(legacy);
        if (value == null) continue;
        // Geçerli anahtar zaten varsa değer onda kalır; eski yazım
        // yalnızca tekilleştirme amacıyla silinir.
        if (!prefs.containsKey(current)) {
          final moved = await _write(prefs, current, value);
          if (!moved) continue; // Desteklenmeyen tip → eski anahtar kalır.
        }
        await prefs.remove(legacy);
      } on Object catch (e) {
        // Tek girdi başarısız olsa da kalanlar denenir; açılış engellenmez.
        debugPrint('Anahtar geçişi başarısız (${entry.key}): $e');
      }
    }
  }

  /// Değeri tipine göre yazar; desteklenmeyen tipte false döner.
  static Future<bool> _write(
    SharedPreferences prefs,
    String key,
    Object value,
  ) async {
    if (value is String) {
      return prefs.setString(key, value);
    } else if (value is bool) {
      return prefs.setBool(key, value);
    } else if (value is int) {
      return prefs.setInt(key, value);
    } else if (value is double) {
      return prefs.setDouble(key, value);
    } else if (value is List && value.every((e) => e is String)) {
      return prefs.setStringList(key, value.cast<String>());
    }
    return false;
  }
}