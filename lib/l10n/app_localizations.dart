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

  /// No description provided for @smartPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Smart Playlists'**
  String get smartPlaylists;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @mostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most Played'**
  String get mostPlayed;

  /// No description provided for @neverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never Played'**
  String get neverPlayed;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @totalPlays.
  ///
  /// In en, this message translates to:
  /// **'Total plays'**
  String get totalPlays;

  /// No description provided for @uniqueSongsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Unique songs played'**
  String get uniqueSongsPlayed;

  /// No description provided for @topArtists.
  ///
  /// In en, this message translates to:
  /// **'Top Artists'**
  String get topArtists;

  /// No description provided for @topGenres.
  ///
  /// In en, this message translates to:
  /// **'Top Genres'**
  String get topGenres;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'Not enough listening data yet'**
  String get noStatsYet;

  /// No description provided for @playCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Played 0 times} =1{Played once} other{Played {count} times}}'**
  String playCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, albums, artists...'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get searchEmptyMessage;

  /// No description provided for @noSearchYet.
  ///
  /// In en, this message translates to:
  /// **'Type something to start searching.'**
  String get noSearchYet;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @songInfo.
  ///
  /// In en, this message translates to:
  /// **'Song Info'**
  String get songInfo;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get infoTitle;

  /// No description provided for @infoArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get infoArtist;

  /// No description provided for @infoAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get infoAlbum;

  /// No description provided for @infoGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get infoGenre;

  /// No description provided for @infoDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get infoDuration;

  /// No description provided for @infoPath.
  ///
  /// In en, this message translates to:
  /// **'File Path'**
  String get infoPath;

  /// No description provided for @infoSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get infoSize;

  /// No description provided for @infoDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get infoDateAdded;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic color'**
  String get settingsDynamicColor;

  /// No description provided for @settingsDynamicColorDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Android 12+ Material You colors'**
  String get settingsDynamicColorDescription;

  /// No description provided for @settingsAmoledDark.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black'**
  String get settingsAmoledDark;

  /// No description provided for @settingsAmoledDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Use pure black surfaces in dark mode'**
  String get settingsAmoledDarkDescription;

  /// No description provided for @settingsGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGroupGeneral;

  /// No description provided for @settingsGroupAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsGroupAppearance;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersionLabel(String version);

  /// No description provided for @settingsAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Resonance is an offline music player for Android. Your data never leaves this device.'**
  String get settingsAboutDescription;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeDefault;

  /// No description provided for @themePresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset: {name}'**
  String themePresetName(String name);

  /// No description provided for @themeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeCustom;

  /// No description provided for @themePresetDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic (Material You)'**
  String get themePresetDynamic;

  /// No description provided for @themePresetFromArtwork.
  ///
  /// In en, this message translates to:
  /// **'From artwork'**
  String get themePresetFromArtwork;

  /// No description provided for @themePresetSeed.
  ///
  /// In en, this message translates to:
  /// **'Custom seed color'**
  String get themePresetSeed;

  /// No description provided for @themeAmoledOn.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black surfaces'**
  String get themeAmoledOn;

  /// No description provided for @themeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get themeHighContrast;

  /// No description provided for @themeSurfaceTint.
  ///
  /// In en, this message translates to:
  /// **'Surface elevation tint'**
  String get themeSurfaceTint;

  /// No description provided for @themeRoundedCorners.
  ///
  /// In en, this message translates to:
  /// **'Rounded corners'**
  String get themeRoundedCorners;

  /// No description provided for @themeDensity.
  ///
  /// In en, this message translates to:
  /// **'Component density'**
  String get themeDensity;

  /// No description provided for @themeDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get themeDensityCompact;

  /// No description provided for @themeDensityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get themeDensityStandard;

  /// No description provided for @themeDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get themeDensityComfortable;

  /// No description provided for @themeFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get themeFont;

  /// No description provided for @themeFontDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeFontDefault;

  /// No description provided for @themeTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get themeTextScale;

  /// No description provided for @playerBackgroundSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid color'**
  String get playerBackgroundSolid;

  /// No description provided for @playerBackgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient from artwork'**
  String get playerBackgroundGradient;

  /// No description provided for @playerBackgroundBlur.
  ///
  /// In en, this message translates to:
  /// **'Blurred artwork'**
  String get playerBackgroundBlur;

  /// No description provided for @playerArtworkSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get playerArtworkSquare;

  /// No description provided for @playerArtworkRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get playerArtworkRounded;

  /// No description provided for @playerArtworkCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get playerArtworkCircle;

  /// No description provided for @listViewCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get listViewCompact;

  /// No description provided for @listViewComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get listViewComfortable;

  /// No description provided for @listViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get listViewGrid;

  /// No description provided for @animationsFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get animationsFull;

  /// No description provided for @animationsReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get animationsReduced;

  /// No description provided for @animationsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get animationsNone;

  /// No description provided for @themeGroupPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get themeGroupPlayer;

  /// No description provided for @themeGroupList.
  ///
  /// In en, this message translates to:
  /// **'Library list'**
  String get themeGroupList;

  /// No description provided for @themeGroupAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get themeGroupAnimation;

  /// No description provided for @themeGroupFont.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get themeGroupFont;

  /// No description provided for @themeGroupShape.
  ///
  /// In en, this message translates to:
  /// **'Shape & density'**
  String get themeGroupShape;

  /// No description provided for @themeGroupColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get themeGroupColor;

  /// No description provided for @themeGroupMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeGroupMode;

  /// No description provided for @themeGroupDarkVariant.
  ///
  /// In en, this message translates to:
  /// **'Dark variant'**
  String get themeGroupDarkVariant;

  /// No description provided for @themeDarkNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal dark'**
  String get themeDarkNormal;

  /// No description provided for @themeDarkAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black'**
  String get themeDarkAmoled;

  /// No description provided for @themeSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Seed color'**
  String get themeSeedColor;

  /// No description provided for @themeResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get themeResetToDefault;

  /// No description provided for @themeResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all appearance settings to their defaults?'**
  String get themeResetConfirm;

  /// No description provided for @themePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Player appearance'**
  String get themePlayerTitle;

  /// No description provided for @themeListTitle.
  ///
  /// In en, this message translates to:
  /// **'Library list appearance'**
  String get themeListTitle;

  /// No description provided for @themePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get themePreviewTitle;

  /// No description provided for @themePreviewSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Song'**
  String get themePreviewSongTitle;

  /// No description provided for @themePreviewSongArtist.
  ///
  /// In en, this message translates to:
  /// **'Sample Artist'**
  String get themePreviewSongArtist;

  /// No description provided for @settingsPlayback.
  ///
  /// In en, this message translates to:
  /// **'Oynatma'**
  String get settingsPlayback;

  /// No description provided for @settingsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Kütüphane'**
  String get settingsLibrary;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Erişilebilirlik'**
  String get settingsAccessibility;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Depolama ve Gelişmiş'**
  String get settingsStorage;

  /// No description provided for @settingsQueue.
  ///
  /// In en, this message translates to:
  /// **'Kuyruk ve Playlist'**
  String get settingsQueue;

  /// No description provided for @seekInterval.
  ///
  /// In en, this message translates to:
  /// **'Sarma süresi'**
  String get seekInterval;

  /// No description provided for @seekIntervalValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String seekIntervalValue(int seconds);

  /// No description provided for @autoResume.
  ///
  /// In en, this message translates to:
  /// **'Uygulama açılınca otomatik devam et'**
  String get autoResume;

  /// No description provided for @pauseOnHeadphone.
  ///
  /// In en, this message translates to:
  /// **'Kulaklık çıkınca duraklat'**
  String get pauseOnHeadphone;

  /// No description provided for @defaultShuffle.
  ///
  /// In en, this message translates to:
  /// **'Varsayılan karıştırma'**
  String get defaultShuffle;

  /// No description provided for @defaultRepeat.
  ///
  /// In en, this message translates to:
  /// **'Varsayılan tekrar modu'**
  String get defaultRepeat;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Kapalı'**
  String get repeatNone;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Tümü'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Tek'**
  String get repeatOne;

  /// No description provided for @minDuration.
  ///
  /// In en, this message translates to:
  /// **'Minimum şarkı süresi'**
  String get minDuration;

  /// No description provided for @scanOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Açılışta kütüphaneyi tara'**
  String get scanOnStartup;

  /// No description provided for @resetGroup.
  ///
  /// In en, this message translates to:
  /// **'Grubu varsayılana sıfırla'**
  String get resetGroup;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Tüm ayarları sıfırla'**
  String get resetAll;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Tüm ayarları varsayılana sıfırlamak istediğinize emin misiniz? Bu işlem geri alınamaz.'**
  String get resetConfirm;

  /// No description provided for @textScale.
  ///
  /// In en, this message translates to:
  /// **'Yazı ölçeği'**
  String get textScale;

  /// No description provided for @reduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Animasyonları azalt'**
  String get reduceAnimations;

  /// No description provided for @largeTouchTargets.
  ///
  /// In en, this message translates to:
  /// **'Büyük dokunma hedefleri'**
  String get largeTouchTargets;

  /// No description provided for @audioSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioSettingsTitle;

  /// No description provided for @equalizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizerTitle;

  /// No description provided for @equalizerEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Equalizer'**
  String get equalizerEnable;

  /// No description provided for @equalizerPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get equalizerPresets;

  /// No description provided for @equalizerSavePreset.
  ///
  /// In en, this message translates to:
  /// **'Save Preset'**
  String get equalizerSavePreset;

  /// No description provided for @equalizerPresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get equalizerPresetName;

  /// No description provided for @loudnessEnhancer.
  ///
  /// In en, this message translates to:
  /// **'Loudness Enhancer'**
  String get loudnessEnhancer;

  /// No description provided for @loudnessGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get loudnessGain;

  /// No description provided for @equalizerNoBands.
  ///
  /// In en, this message translates to:
  /// **'Equalizer is not supported on this device.'**
  String get equalizerNoBands;

  /// No description provided for @eqPresetFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get eqPresetFlat;

  /// No description provided for @eqPresetRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get eqPresetRock;

  /// No description provided for @eqPresetPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get eqPresetPop;

  /// No description provided for @eqPresetJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get eqPresetJazz;

  /// No description provided for @eqPresetClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get eqPresetClassical;

  /// No description provided for @eqPresetBass.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get eqPresetBass;

  /// No description provided for @eqPresetTreble.
  ///
  /// In en, this message translates to:
  /// **'Treble Boost'**
  String get eqPresetTreble;

  /// No description provided for @eqPresetVocal.
  ///
  /// In en, this message translates to:
  /// **'Vocal'**
  String get eqPresetVocal;

  /// No description provided for @eqGroupBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in Presets'**
  String get eqGroupBuiltIn;

  /// No description provided for @eqGroupCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Presets'**
  String get eqGroupCustom;

  /// No description provided for @playbackSpeedPitch.
  ///
  /// In en, this message translates to:
  /// **'Speed & Pitch'**
  String get playbackSpeedPitch;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playbackSpeed;

  /// No description provided for @playbackPitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get playbackPitch;

  /// No description provided for @playbackReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get playbackReset;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'End of track'**
  String get sleepTimerEndOfTrack;

  /// No description provided for @sleepTimerSetFor.
  ///
  /// In en, this message translates to:
  /// **'Timer set for {minutes} min'**
  String sleepTimerSetFor(int minutes);

  /// No description provided for @sleepTimerEndOfTrackSet.
  ///
  /// In en, this message translates to:
  /// **'Will stop after this track'**
  String get sleepTimerEndOfTrackSet;

  /// No description provided for @gaplessPlayback.
  ///
  /// In en, this message translates to:
  /// **'Gapless playback'**
  String get gaplessPlayback;

  /// No description provided for @skipSilence.
  ///
  /// In en, this message translates to:
  /// **'Skip silence'**
  String get skipSilence;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @tagViewer.
  ///
  /// In en, this message translates to:
  /// **'Tag Info'**
  String get tagViewer;

  /// No description provided for @tagTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tagTitle;

  /// No description provided for @tagArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get tagArtist;

  /// No description provided for @tagAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get tagAlbum;

  /// No description provided for @tagGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get tagGenre;

  /// No description provided for @tagYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get tagYear;

  /// No description provided for @tagReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Tags are read-only. Use your device\'s file manager to edit them.'**
  String get tagReadOnlyNote;

  /// No description provided for @tagReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read tags.'**
  String get tagReadError;

  /// No description provided for @replayGain.
  ///
  /// In en, this message translates to:
  /// **'ReplayGain'**
  String get replayGain;

  /// No description provided for @replayGainEnable.
  ///
  /// In en, this message translates to:
  /// **'Apply ReplayGain'**
  String get replayGainEnable;

  /// No description provided for @replayGainEnableDesc.
  ///
  /// In en, this message translates to:
  /// **'Normalizes volume based on track loudness tags'**
  String get replayGainEnableDesc;

  /// No description provided for @tagsArtworkSettings.
  ///
  /// In en, this message translates to:
  /// **'Tags & Artwork'**
  String get tagsArtworkSettings;

  /// No description provided for @clearArtworkCache.
  ///
  /// In en, this message translates to:
  /// **'Clear artwork cache'**
  String get clearArtworkCache;

  /// No description provided for @artworkCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Artwork cache cleared'**
  String get artworkCacheCleared;

  /// No description provided for @seekBarStyle.
  ///
  /// In en, this message translates to:
  /// **'Seek Bar Style'**
  String get seekBarStyle;

  /// No description provided for @seekBarClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get seekBarClassic;

  /// No description provided for @seekBarThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get seekBarThin;

  /// No description provided for @seekBarWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get seekBarWaveform;
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
