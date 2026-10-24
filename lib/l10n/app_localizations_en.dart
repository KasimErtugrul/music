// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Resonance';

  @override
  String get tabHome => 'Home';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabSettings => 'Settings';

  @override
  String get libraryTabSongs => 'Songs';

  @override
  String get libraryTabAlbums => 'Albums';

  @override
  String get libraryTabArtists => 'Artists';

  @override
  String get libraryTabGenres => 'Genres';

  @override
  String get libraryTabFolders => 'Folders';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'No albums',
    );
    return '$_temp0';
  }

  @override
  String get debugLanguageToggle => 'Switch language (temporary)';

  @override
  String get permissionTitle => 'Offline music player';

  @override
  String get permissionSubtitle =>
      'To play the music on your device, Resonance needs access to your audio files.';

  @override
  String get permissionMediaTitle => 'Music and audio files';

  @override
  String get permissionMediaDescription =>
      'Required to list and play the songs in your local library.';

  @override
  String get permissionGrantButton => 'Allow access';

  @override
  String get permissionGrantedLabel => 'Access granted';

  @override
  String get permissionDeniedTitle => 'Permission denied';

  @override
  String get permissionDeniedDescription =>
      'Without access to your music files, Resonance can\'t build your library. You can try again.';

  @override
  String get permissionPermanentlyDeniedTitle =>
      'Permission permanently denied';

  @override
  String get permissionPermanentlyDeniedDescription =>
      'Access was blocked. To play your music, allow it manually in the app settings.';

  @override
  String get permissionOpenSettingsButton => 'Open app settings';

  @override
  String get permissionContinueButton => 'Continue';

  @override
  String get permissionNotificationTitle => 'Notification access';

  @override
  String get permissionNotificationBadge => 'Android 13+';

  @override
  String get permissionNotificationDescription =>
      'Optional. Shows playback controls on the lock screen and in the notification shade. Playback works without it.';

  @override
  String get permissionPrivacyTitle => 'Privacy and offline promise';

  @override
  String get permissionPrivacyBody =>
      'Resonance never connects to the internet. Your data stays on this device and is never sent over a network.';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get unknownGenre => 'Unknown genre';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortFieldTitle => 'Title';

  @override
  String get sortFieldArtist => 'Artist';

  @override
  String get sortFieldAlbum => 'Album';

  @override
  String get sortFieldDateAdded => 'Date added';

  @override
  String get sortFieldDuration => 'Duration';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get libraryEmptySongsTitle => 'No songs found';

  @override
  String get libraryEmptySongsMessage =>
      'Your library doesn\'t contain any songs yet. Make sure music files are on this device.';

  @override
  String get libraryEmptyAlbumsTitle => 'No albums';

  @override
  String get libraryEmptyAlbumsMessage =>
      'Albums will appear here once your library has been scanned.';

  @override
  String get libraryEmptyArtistsTitle => 'No artists';

  @override
  String get libraryEmptyArtistsMessage =>
      'Artists will appear here once your library has been scanned.';

  @override
  String get libraryEmptyGenresTitle => 'No genres';

  @override
  String get libraryEmptyGenresMessage =>
      'Genres will appear here once your library has been scanned.';

  @override
  String get libraryEmptyFoldersTitle => 'No music folders';

  @override
  String get libraryEmptyFoldersMessage =>
      'Folders containing music will appear here.';

  @override
  String get libraryLoadErrorTitle => 'Couldn\'t load library';

  @override
  String get libraryLoadErrorMessage =>
      'An error occurred while reading your library.';

  @override
  String get folderRootName => 'Storage';

  @override
  String get folderSubfoldersTitle => 'Subfolders';

  @override
  String get folderSongsTitle => 'Songs in this folder';

  @override
  String get spikeTitle => 'Spike Test Page';

  @override
  String get spikeOpenButton => 'Open Spike Test';

  @override
  String get spikeScanButton => 'Scan Library';

  @override
  String spikeStats(int total, int elapsed) {
    return 'Stats: $total songs ($elapsed ms)';
  }

  @override
  String spikeMissingStats(int noArtist, int noGenre) {
    return 'Missing artist: $noArtist, missing genre: $noGenre';
  }

  @override
  String get spikeLoadError => 'Failed to load stats';

  @override
  String get spikeNotScanned => 'Not scanned yet';

  @override
  String get spikeEmpty => 'No items found';

  @override
  String get backToParent => 'Back';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get playerTitle => 'Player';

  @override
  String get playerNoSong => 'Nothing is playing right now';

  @override
  String get playlistsTitle => 'Playlists';

  @override
  String get createPlaylist => 'New playlist';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get renamePlaylist => 'Rename';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get deletePlaylistConfirm =>
      'Are you sure you want to delete this playlist?';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String get noPlaylistsMessage => 'Tap + to create your first playlist.';

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get queueTitle => 'Queue';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get queueEmpty => 'The queue is empty';

  @override
  String get clearQueue => 'Clear queue';

  @override
  String get clearQueueConfirm => 'Are you sure you want to clear the queue?';

  @override
  String get queueCleared => 'Queue cleared';

  @override
  String get favorites => 'Favorites';

  @override
  String get history => 'History';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get historyEmpty => 'No history yet';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear your play history?';

  @override
  String get smartPlaylists => 'Smart Playlists';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String get mostPlayed => 'Most Played';

  @override
  String get neverPlayed => 'Never Played';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get totalPlays => 'Total plays';

  @override
  String get uniqueSongsPlayed => 'Unique songs played';

  @override
  String get topArtists => 'Top Artists';

  @override
  String get topGenres => 'Top Genres';

  @override
  String get noStatsYet => 'Not enough listening data yet';

  @override
  String playCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Played $count times',
      one: 'Played once',
      zero: 'Played 0 times',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search songs, albums, artists...';

  @override
  String get searchEmptyTitle => 'No results';

  @override
  String get searchEmptyMessage => 'Try a different search term.';

  @override
  String get noSearchYet => 'Type something to start searching.';

  @override
  String get share => 'Share';

  @override
  String get songInfo => 'Song Info';

  @override
  String get infoTitle => 'Title';

  @override
  String get infoArtist => 'Artist';

  @override
  String get infoAlbum => 'Album';

  @override
  String get infoGenre => 'Genre';

  @override
  String get infoDuration => 'Duration';

  @override
  String get infoPath => 'File Path';

  @override
  String get infoSize => 'File Size';

  @override
  String get infoDateAdded => 'Date Added';

  @override
  String get searchResults => 'Search Results';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsThemeMode => 'Theme mode';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDynamicColor => 'Dynamic color';

  @override
  String get settingsDynamicColorDescription =>
      'Use Android 12+ Material You colors';

  @override
  String get settingsAmoledDark => 'AMOLED black';

  @override
  String get settingsAmoledDarkDescription =>
      'Use pure black surfaces in dark mode';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupAppearance => 'Appearance';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutDescription =>
      'Resonance is an offline music player for Android. Your data never leaves this device.';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get themeDefault => 'Default';

  @override
  String themePresetName(String name) {
    return 'Preset: $name';
  }

  @override
  String get themeCustom => 'Custom';

  @override
  String get themePresetDynamic => 'Dynamic (Material You)';

  @override
  String get themePresetFromArtwork => 'From artwork';

  @override
  String get themePresetSeed => 'Custom seed color';

  @override
  String get themeAmoledOn => 'AMOLED black surfaces';

  @override
  String get themeHighContrast => 'High contrast';

  @override
  String get themeSurfaceTint => 'Surface elevation tint';

  @override
  String get themeRoundedCorners => 'Rounded corners';

  @override
  String get themeDensity => 'Component density';

  @override
  String get themeDensityCompact => 'Compact';

  @override
  String get themeDensityStandard => 'Standard';

  @override
  String get themeDensityComfortable => 'Comfortable';

  @override
  String get themeFont => 'Font';

  @override
  String get themeFontDefault => 'Default';

  @override
  String get themeTextScale => 'Text scale';

  @override
  String get playerBackgroundSolid => 'Solid color';

  @override
  String get playerBackgroundGradient => 'Gradient from artwork';

  @override
  String get playerBackgroundBlur => 'Blurred artwork';

  @override
  String get playerArtworkSquare => 'Square';

  @override
  String get playerArtworkRounded => 'Rounded';

  @override
  String get playerArtworkCircle => 'Circle';

  @override
  String get listViewCompact => 'Compact';

  @override
  String get listViewComfortable => 'Comfortable';

  @override
  String get listViewGrid => 'Grid';

  @override
  String get animationsFull => 'Full';

  @override
  String get animationsReduced => 'Reduced';

  @override
  String get animationsNone => 'None';

  @override
  String get themeGroupPlayer => 'Player';

  @override
  String get themeGroupList => 'Library list';

  @override
  String get themeGroupAnimation => 'Animations';

  @override
  String get themeGroupFont => 'Typography';

  @override
  String get themeGroupShape => 'Shape & density';

  @override
  String get themeGroupColor => 'Color';

  @override
  String get themeGroupMode => 'Theme mode';

  @override
  String get themeGroupDarkVariant => 'Dark variant';

  @override
  String get themeDarkNormal => 'Normal dark';

  @override
  String get themeDarkAmoled => 'AMOLED black';

  @override
  String get themeSeedColor => 'Seed color';

  @override
  String get themeResetToDefault => 'Reset to default';

  @override
  String get themeResetConfirm =>
      'Reset all appearance settings to their defaults?';

  @override
  String get themePlayerTitle => 'Player appearance';

  @override
  String get themeListTitle => 'Library list appearance';

  @override
  String get themePreviewTitle => 'Preview';

  @override
  String get themePreviewSongTitle => 'Sample Song';

  @override
  String get themePreviewSongArtist => 'Sample Artist';

  @override
  String get settingsPlayback => 'Oynatma';

  @override
  String get settingsLibrary => 'Kütüphane';

  @override
  String get settingsAccessibility => 'Erişilebilirlik';

  @override
  String get settingsStorage => 'Depolama ve Gelişmiş';

  @override
  String get settingsQueue => 'Kuyruk ve Playlist';

  @override
  String get seekInterval => 'Sarma süresi';

  @override
  String seekIntervalValue(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get autoResume => 'Uygulama açılınca otomatik devam et';

  @override
  String get pauseOnHeadphone => 'Kulaklık çıkınca duraklat';

  @override
  String get defaultShuffle => 'Varsayılan karıştırma';

  @override
  String get defaultRepeat => 'Varsayılan tekrar modu';

  @override
  String get repeatNone => 'Kapalı';

  @override
  String get repeatAll => 'Tümü';

  @override
  String get repeatOne => 'Tek';

  @override
  String get minDuration => 'Minimum şarkı süresi';

  @override
  String get scanOnStartup => 'Açılışta kütüphaneyi tara';

  @override
  String get resetGroup => 'Grubu varsayılana sıfırla';

  @override
  String get resetAll => 'Tüm ayarları sıfırla';

  @override
  String get resetConfirm =>
      'Tüm ayarları varsayılana sıfırlamak istediğinize emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get textScale => 'Yazı ölçeği';

  @override
  String get reduceAnimations => 'Animasyonları azalt';

  @override
  String get largeTouchTargets => 'Büyük dokunma hedefleri';

  @override
  String get audioSettingsTitle => 'Audio';

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerEnable => 'Enable Equalizer';

  @override
  String get equalizerPresets => 'Presets';

  @override
  String get equalizerSavePreset => 'Save Preset';

  @override
  String get equalizerPresetName => 'Preset Name';

  @override
  String get loudnessEnhancer => 'Loudness Enhancer';

  @override
  String get loudnessGain => 'Gain';

  @override
  String get equalizerNoBands => 'Equalizer is not supported on this device.';

  @override
  String get eqPresetFlat => 'Flat';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Classical';

  @override
  String get eqPresetBass => 'Bass Boost';

  @override
  String get eqPresetTreble => 'Treble Boost';

  @override
  String get eqPresetVocal => 'Vocal';

  @override
  String get eqGroupBuiltIn => 'Built-in Presets';

  @override
  String get eqGroupCustom => 'Custom Presets';

  @override
  String get playbackSpeedPitch => 'Speed & Pitch';

  @override
  String get playbackSpeed => 'Speed';

  @override
  String get playbackPitch => 'Pitch';

  @override
  String get playbackReset => 'Reset';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String get sleepTimerEndOfTrack => 'End of track';

  @override
  String sleepTimerSetFor(int minutes) {
    return 'Timer set for $minutes min';
  }

  @override
  String get sleepTimerEndOfTrackSet => 'Will stop after this track';

  @override
  String get gaplessPlayback => 'Gapless playback';

  @override
  String get skipSilence => 'Skip silence';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get tagViewer => 'Tag Info';

  @override
  String get tagTitle => 'Title';

  @override
  String get tagArtist => 'Artist';

  @override
  String get tagAlbum => 'Album';

  @override
  String get tagGenre => 'Genre';

  @override
  String get tagYear => 'Year';

  @override
  String get tagReadOnlyNote =>
      'Tags are read-only. Use your device\'s file manager to edit them.';

  @override
  String get tagReadError => 'Could not read tags.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainEnable => 'Apply ReplayGain';

  @override
  String get replayGainEnableDesc =>
      'Normalizes volume based on track loudness tags';

  @override
  String get tagsArtworkSettings => 'Tags & Artwork';

  @override
  String get clearArtworkCache => 'Clear artwork cache';

  @override
  String get artworkCacheCleared => 'Artwork cache cleared';

  @override
  String get seekBarStyle => 'Seek Bar Style';

  @override
  String get seekBarClassic => 'Classic';

  @override
  String get seekBarThin => 'Thin';

  @override
  String get seekBarWaveform => 'Waveform';

  @override
  String get excludedFolders => 'Hidden Folders';

  @override
  String get excludedFoldersDesc => 'Folders excluded from the library';

  @override
  String get addExcludedFolder => 'Add Folder';

  @override
  String get noExcludedFolders => 'No hidden folders.';

  @override
  String get externalOpenError => 'Could not open the external file.';

  @override
  String get externalOpenNoPermission =>
      'File permission denied. Cannot play external file.';

  @override
  String get waveformViewer => 'Waveform View';

  @override
  String get waveformPreparing => 'Preparing waveform…';

  @override
  String get waveformFirstTimeNote =>
      'Analyzing the track for the first time. Subsequent openings are instant.';

  @override
  String get waveformUnavailable =>
      'Waveform could not be generated for this track.';

  @override
  String get waveformNoFilePath =>
      'This track has no local file path. Waveform is only available for local files.';
}
