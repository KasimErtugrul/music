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
  String get spikeLoadError => 'Failed to load stats';

  @override
  String get spikeNotScanned => 'Not scanned yet';

  @override
  String get spikeEmpty => 'No items found';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get playerTitle => 'Player';

  @override
  String get backToParent => 'Back';
}
