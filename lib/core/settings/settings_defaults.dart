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
///
/// Gün 8: `themeMode` da kaldırıldı — taban commit'ten beri okuyucusu yoktu
/// (Gün 4 bulgusu). Tema modu `active_theme_settings` JSON'undaki
/// ThemeSettings.themeMode alanıyla yönetilir; ayrıştırma varsayılanı
/// ThemeMode.system'dır (theme_engine.dart).
abstract final class SettingsDefaults {
  /// Prefs'te dil anahtarı yokken kullanılır (SettingsRepository.load).
  /// Geçerli değerler: 'system' | 'tr' | 'en'.
  static const String languageCode = 'system';
}