import 'package:resonance/core/settings/settings_keys.dart';

/// Gün 1: Gerçek SharedPreferences kalıcılık anahtarlarının tek doğruluk
/// kaynağı.
///
/// İki katman birbirine karıştırılmamalıdır:
/// * [SettingsKeys] — ayar arayüzünün (SettingsRegistry) kimlikleridir;
///   çoğu gerçek bir prefs anahtarı DEĞİLDİR (kalıcılık playback_settings /
///   library_settings JSON dizelerinin içindedir).
/// * [SettingsPersistence] — diskte gerçekten yazılan prefs anahtarlarıdır.
///   Yedekleme (BackupDatasource) yalnızca bu katmanla çalışır.
///
/// Kural: Uygulamada yeni bir prefs anahtarı yazan kod ekliyorsan anahtarı
/// buraya ve [backupKeys] listesine ekle. Aksi halde
/// test/core/settings_backup_keys_test.dart kırılır — bu bilinçli bir
/// güvenlik ağıdır: kalıcı kullanıcı verisi sessizce yedek dışında kalmaz.
abstract final class SettingsPersistence {
  // ---------------------------------------------------------------------------
  // Yedeklenen anahtarlar (kullanıcı verisi / tercihleri)
  // ---------------------------------------------------------------------------

  /// SettingsController: 'system' | 'tr' | 'en'.
  static const String languageCode = SettingsKeys.languageCode;

  /// PreferencesRepositoryImpl: PlaybackSettingsModel JSON'u.
  static const String playbackSettings = 'playback_settings';

  /// PreferencesRepositoryImpl: LibrarySettingsModel JSON'u.
  static const String librarySettings = 'library_settings';

  /// ThemeRepositoryImpl: ThemeSettings JSON'u.
  static const String activeThemeSettings = 'active_theme_settings';

  /// EqualizerRepositoryImpl: ekolayzer anahtarı (bool).
  static const String equalizerEnabled = 'equalizer_enabled';

  /// EqualizerRepositoryImpl: bant kazançları JSON'u (dB listesi).
  static const String equalizerGains = 'equalizer_gains';

  /// EqualizerRepositoryImpl: manuel loudness değeri (double, dB).
  static const String equalizerLoudness = 'equalizer_loudness';

  /// HomeWidgetController: widget şeffaf modu (bool).
  /// Android tarafı (MusicWidgetProvider.kt) aynı anahtarı okur; dizgeyi
  /// değiştirme.
  static const String widgetTransparent = 'widget_transparent';

  /// SearchController: son aramalar JSON'u.
  static const String searchHistory = 'search_history';

  /// AutoBackupController: otomatik yedekleme tercihi (bool).
  static const String autoBackupEnabled = 'settings_auto_backup_enabled';

  /// AutoBackupController: otomatik yedekleme sıklığı ('daily' | 'weekly').
  static const String autoBackupFrequency = 'settings_auto_backup_frequency';

  /// AutoBackupController: saklanacak yedek sayısı (int).
  static const String autoBackupKeep = 'settings_auto_backup_keep';

  /// Dışa aktarmaya giren TÜM prefs anahtarları.
  static const List<String> backupKeys = <String>[
    languageCode,
    playbackSettings,
    librarySettings,
    activeThemeSettings,
    equalizerEnabled,
    equalizerGains,
    equalizerLoudness,
    widgetTransparent,
    searchHistory,
    autoBackupEnabled,
    autoBackupFrequency,
    autoBackupKeep,
  ];

  // ---------------------------------------------------------------------------
  // Bilinçli olarak yedeklenmeyen anahtarlar (iş evi / oturum bilgisi)
  // ---------------------------------------------------------------------------

  /// BackupController: son manuel yedek zamanı (int, epoch ms).
  static const String lastBackupAt = 'last_backup_at';

  /// AutoBackupController: son otomatik yedek zamanı (int, epoch ms).
  static const String autoBackupLast = 'settings_auto_backup_last';

  /// Yedeklenmeyen anahtarlar. Test bu listeyle [backupKeys] ayrımını denetler.
  static const List<String> notBackedUpKeys = <String>[
    lastBackupAt,
    autoBackupLast,
  ];
}
