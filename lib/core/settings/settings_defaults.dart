/// Uygulama ayarlarının varsayılan değerleri (Gün 4 gözden geçirmesi).
///
/// Katmanlar: [SettingsKeys] arayüz kimlikleri, [SettingsPersistence]
/// diskteki gerçek prefs anahtarları, bu sınıf ise okunacak değer yokken
/// kullanılan varsayılanlardır.
///
/// Gün 4: `dynamicColor` ve `amoledDark` buradan kaldırıldı — ikisinin de
/// okuyucusu yoktu ve gerçek karşılıkları ThemeSettings'in `colorSource` /
/// `amoled` alanları ile `theme_color_source` / `theme_amoled`
/// anahtarlarıdır (settings_keys.dart başındaki Görev 4.2 notuna bakın).
/// Eski yedeklerde karşılaşılırsa `dynamic_color` / `amoled_dark`
/// anahtarları, Gün 1'deki tip güvenli içe aktarma tarafından bilinmeyen
/// anahtar sayılarak yok sayılır; çökme olmaz, mevcut değerler korunur.
abstract final class SettingsDefaults {
  /// Prefs'te dil anahtarı yokken kullanılır (SettingsRepository.load).
  /// Geçerli değerler: 'system' | 'tr' | 'en'.
  static const String languageCode = 'system';

  /// Gün 4 notu: Bu sabitin de okuyucusu kalmadı — tema modu artık
  /// `active_theme_settings` JSON'undaki ThemeSettings.themeMode alanıyla
  /// yönetilir (ayrıştırma varsayılanı ThemeMode.system, theme_engine.dart).
  /// Gün 4 kapsamında yalnız `dynamicColor` ve `amoledDark` listelendiği
  /// için bu sabite dokunulmadı; sonraki temizlikte kaldırılabilir.
  static const String themeMode = 'system';
}