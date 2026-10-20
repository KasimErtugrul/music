import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Resonance'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @libraryTabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get libraryTabSongs;

  /// No description provided for @libraryTabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryTabAlbums;

  /// No description provided for @libraryTabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryTabArtists;

  /// No description provided for @libraryTabGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get libraryTabGenres;

  /// No description provided for @libraryTabFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get libraryTabFolders;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Number of songs
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String songCount(int count);

  /// Temporary Day 1 button; removed on Day 17 when the language picker is added
  ///
  /// In en, this message translates to:
  /// **'Switch language (temporary)'**
  String get debugLanguageToggle;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline music player'**
  String get permissionTitle;

  /// No description provided for @permissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To play the music on your device, Resonance needs access to your audio files.'**
  String get permissionSubtitle;

  /// No description provided for @permissionMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Music and audio files'**
  String get permissionMediaTitle;

  /// No description provided for @permissionMediaDescription.
  ///
  /// In en, this message translates to:
  /// **'Required to list and play the songs in your local library.'**
  String get permissionMediaDescription;

  /// No description provided for @permissionGrantButton.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get permissionGrantButton;

  /// No description provided for @permissionGrantedLabel.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get permissionGrantedLabel;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'Without access to your music files, Resonance can\'t build your library. You can try again.'**
  String get permissionDeniedDescription;

  /// No description provided for @permissionPermanentlyDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission permanently denied'**
  String get permissionPermanentlyDeniedTitle;

  /// No description provided for @permissionPermanentlyDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'Access was blocked. To play your music, allow it manually in the app settings.'**
  String get permissionPermanentlyDeniedDescription;

  /// No description provided for @permissionOpenSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get permissionOpenSettingsButton;

  /// No description provided for @permissionContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permissionContinueButton;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationBadge.
  ///
  /// In en, this message translates to:
  /// **'Android 13+'**
  String get permissionNotificationBadge;

  /// No description provided for @permissionNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional. Shows playback controls on the lock screen and in the notification shade. Playback works without it.'**
  String get permissionNotificationDescription;

  /// No description provided for @permissionPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and offline promise'**
  String get permissionPrivacyTitle;

  /// No description provided for @permissionPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Resonance never connects to the internet. Your data stays on this device and is never sent over a network.'**
  String get permissionPrivacyBody;

  /// Temporary Day 3 button; removed when the real Songs tab lands on Day 5
  ///
  /// In en, this message translates to:
  /// **'Raw song list (Day 3 spike)'**
  String get spikeOpenButton;

  /// No description provided for @spikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw song list'**
  String get spikeTitle;

  /// No description provided for @spikeScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan library'**
  String get spikeScanButton;

  /// Temporary Day 3 spike statistics
  ///
  /// In en, this message translates to:
  /// **'{count} songs, {ms} ms'**
  String spikeStats(int count, int ms);

  /// Temporary Day 3 spike statistics
  ///
  /// In en, this message translates to:
  /// **'No artist: {noArtist}, no genre: {noGenre}'**
  String spikeMissingStats(int noArtist, int noGenre);

  /// No description provided for @spikeNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Tap scan to read your library.'**
  String get spikeNotScanned;

  /// No description provided for @spikeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No songs found.'**
  String get spikeEmpty;

  /// No description provided for @spikeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the library.'**
  String get spikeLoadError;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
