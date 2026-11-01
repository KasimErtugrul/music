abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String permission = '/permission';
  static const String home = '/home';
  static const String songs = '/songs';
  static const String albumDetail = '/album';
  static const String artistDetail = '/artist';
  static const String genreDetail = '/genre';
  static const String queue = '/queue';
  static const String player = '/player';
  static const String playlistDetail = '/playlist-detail';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String smartPlaylists = '/smart-playlists';
  static const String stats = '/stats';
  // Gün 13 (Karar): «Gelişmiş» sayfa Görünüm'e birleşti; eski
  // '/settings/theme' rotası ve ThemeSettingsPage kaldırıldı.
  static const String themeGallery = '/settings/theme/gallery';
  static const String fontSettings = '/settings/font';
  static const String playerStyle = '/settings/player-style';
  static const String listStyle = '/settings/list-style';
  static const String audioSettings = '/settings/audio';
    static const String backup = '/settings/backup';
    static const String externalPlayer = '/external-player';
static const String notificationSettings = '/settings/notifications';
  // Gün 17 (Kasa): tam ekran özel rota — iki bölmeli ayar düzenine gömülmez;
  // hassas içerik yalnız kendi ekranında gösterilir.
  static const String vault = '/vault';

}
