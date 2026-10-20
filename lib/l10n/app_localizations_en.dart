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
}
