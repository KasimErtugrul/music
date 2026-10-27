/// Görev 4.2: SettingsRegistry anahtarları.
///
/// Eskiden burada themeMode / dynamicColor / amoledDark anahtarları vardı;
/// hiçbir girdi veya tüketici olmadıkları için ölüydüler (analiz: registry
/// girdileri ekranda render edilmiyor). Kaldırıldılar. Yerine, registry'nin
/// uygulamanın gerçek ayar haritası olması için tüm girdilerin anahtarları
/// burada tanımlıdır. Not: 'theme_mode' artık gerçek bir girdiyle (Tema
/// ayarları sayfası) canlıdır; 'dynamic_color' ve 'amoled_dark' ise gerçek
/// karşılıkları olan 'theme_color_source' ve 'theme_amoled' ile değiştirildi.
abstract final class SettingsKeys {
  static const String languageCode = 'language_code';
  static const String seekInterval = 'seek_interval';
  static const String autoResume = 'auto_resume';
  static const String pauseHeadphone = 'pause_headphone';
  static const String defaultShuffle = 'default_shuffle';
  static const String skipSilence = 'skip_silence';
  static const String replayGain = 'replay_gain';
  static const String defaultRepeat = 'default_repeat';
  static const String scanOnStartup = 'scan_on_startup';
  static const String minDuration = 'min_duration';
  static const String excludedFolders = 'excluded_folders';
  static const String audioEffects = 'audio_effects';
  static const String widgetTransparency = 'widget_transparency';
  static const String tagsArtwork = 'tags_artwork';
  static const String backupRestore = 'backup_restore';
  static const String about = 'about';
  static const String themeMode = 'theme_mode';
  static const String themeColorSource = 'theme_color_source';
  static const String themeAmoled = 'theme_amoled';
  static const String themeHighContrast = 'theme_high_contrast';
  static const String themeFont = 'theme_font';
  static const String themeTextScale = 'theme_text_scale';
  static const String themeAnimationLevel = 'theme_animation_level';
  static const String themePlayerStyle = 'theme_player_style';
  static const String themeListStyle = 'theme_list_style';
}
