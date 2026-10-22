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

  /// Number of albums
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No albums} =1{1 album} other{{count} albums}}'**
  String albumCount(int count);

  /// No description provided for @debugLanguageToggle.
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

  /// No description provided for @unknownGenre.
  ///
  /// In en, this message translates to:
  /// **'Unknown genre'**
  String get unknownGenre;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortFieldTitle;

  /// No description provided for @sortFieldArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortFieldArtist;

  /// No description provided for @sortFieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortFieldAlbum;

  /// No description provided for @sortFieldDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortFieldDateAdded;

  /// No description provided for @sortFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortFieldDuration;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @libraryEmptySongsTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get libraryEmptySongsTitle;

  /// No description provided for @libraryEmptySongsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your library doesn\'t contain any songs yet. Make sure music files are on this device.'**
  String get libraryEmptySongsMessage;

  /// No description provided for @libraryEmptyAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get libraryEmptyAlbumsTitle;

  /// No description provided for @libraryEmptyAlbumsMessage.
  ///
  /// In en, this message translates to:
  /// **'Albums will appear here once your library has been scanned.'**
  String get libraryEmptyAlbumsMessage;

  /// No description provided for @libraryEmptyArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get libraryEmptyArtistsTitle;

  /// No description provided for @libraryEmptyArtistsMessage.
  ///
  /// In en, this message translates to:
  /// **'Artists will appear here once your library has been scanned.'**
  String get libraryEmptyArtistsMessage;

  /// No description provided for @libraryEmptyGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'No genres'**
  String get libraryEmptyGenresTitle;

  /// No description provided for @libraryEmptyGenresMessage.
  ///
  /// In en, this message translates to:
  /// **'Genres will appear here once your library has been scanned.'**
  String get libraryEmptyGenresMessage;

  /// No description provided for @libraryEmptyFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'No music folders'**
  String get libraryEmptyFoldersTitle;

  /// No description provided for @libraryEmptyFoldersMessage.
  ///
  /// In en, this message translates to:
  /// **'Folders containing music will appear here.'**
  String get libraryEmptyFoldersMessage;

  /// No description provided for @libraryLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load library'**
  String get libraryLoadErrorTitle;

  /// No description provided for @libraryLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while reading your library.'**
  String get libraryLoadErrorMessage;

  /// No description provided for @folderRootName.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get folderRootName;

  /// No description provided for @folderSubfoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Subfolders'**
  String get folderSubfoldersTitle;

  /// No description provided for @folderSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs in this folder'**
  String get folderSongsTitle;

  /// No description provided for @spikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Spike Test Page'**
  String get spikeTitle;

  /// No description provided for @spikeOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Open Spike Test'**
  String get spikeOpenButton;

  /// No description provided for @spikeScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan Library'**
  String get spikeScanButton;

  /// No description provided for @spikeStats.
  ///
  /// In en, this message translates to:
  /// **'Stats: {total} songs ({elapsed} ms)'**
  String spikeStats(int total, int elapsed);

  /// No description provided for @spikeMissingStats.
  ///
  /// In en, this message translates to:
  /// **'Missing artist: {noArtist}, missing genre: {noGenre}'**
  String spikeMissingStats(int noArtist, int noGenre);

  /// No description provided for @spikeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stats'**
  String get spikeLoadError;

  /// No description provided for @spikeNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get spikeNotScanned;

  /// No description provided for @spikeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get spikeEmpty;

  /// No description provided for @backToParent.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backToParent;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerTitle;

  /// No description provided for @playerNoSong.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing right now'**
  String get playerNoSong;

  /// No description provided for @playlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsTitle;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get createPlaylist;

  /// No description provided for @playlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameLabel;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this playlist?'**
  String get deletePlaylistConfirm;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylists;

  /// No description provided for @noPlaylistsMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first playlist.'**
  String get noPlaylistsMessage;

  /// No description provided for @playlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmpty;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty'**
  String get queueEmpty;

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get clearQueue;

  /// No description provided for @clearQueueConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the queue?'**
  String get clearQueueConfirm;

  /// No description provided for @queueCleared.
  ///
  /// In en, this message translates to:
  /// **'Queue cleared'**
  String get queueCleared;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your play history?'**
  String get clearHistoryConfirm;
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
