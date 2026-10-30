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

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

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
  /// **'Playback'**
  String get settingsPlayback;

  /// No description provided for @settingsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage & Advanced'**
  String get settingsStorage;

  /// No description provided for @settingsQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue & Playlist'**
  String get settingsQueue;

  /// No description provided for @seekInterval.
  ///
  /// In en, this message translates to:
  /// **'Seek interval'**
  String get seekInterval;

  /// No description provided for @seekIntervalValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String seekIntervalValue(int seconds);

  /// No description provided for @autoResume.
  ///
  /// In en, this message translates to:
  /// **'Auto-resume on app start'**
  String get autoResume;

  /// No description provided for @pauseOnHeadphone.
  ///
  /// In en, this message translates to:
  /// **'Pause when headphones disconnected'**
  String get pauseOnHeadphone;

  /// No description provided for @defaultShuffle.
  ///
  /// In en, this message translates to:
  /// **'Default shuffle'**
  String get defaultShuffle;

  /// No description provided for @defaultRepeat.
  ///
  /// In en, this message translates to:
  /// **'Default repeat mode'**
  String get defaultRepeat;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get repeatNone;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get repeatOne;

  /// No description provided for @minDuration.
  ///
  /// In en, this message translates to:
  /// **'Minimum song duration'**
  String get minDuration;

  /// No description provided for @scanOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Scan library on startup'**
  String get scanOnStartup;

  /// No description provided for @scanOnStartupHint.
  ///
  /// In en, this message translates to:
  /// **'New and changed files are picked up automatically'**
  String get scanOnStartupHint;

  /// No description provided for @libraryScanUpdated.
  ///
  /// In en, this message translates to:
  /// **'Library updated'**
  String get libraryScanUpdated;

  /// No description provided for @resetGroup.
  ///
  /// In en, this message translates to:
  /// **'Reset group to defaults'**
  String get resetGroup;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings'**
  String get resetAll;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to their defaults? This cannot be undone.'**
  String get resetConfirm;

  /// No description provided for @textScale.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get textScale;

  /// No description provided for @reduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce animations'**
  String get reduceAnimations;

  /// No description provided for @largeTouchTargets.
  ///
  /// In en, this message translates to:
  /// **'Large touch targets'**
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

  /// No description provided for @excludedFolders.
  ///
  /// In en, this message translates to:
  /// **'Hidden Folders'**
  String get excludedFolders;

  /// No description provided for @excludedFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Folders excluded from the library'**
  String get excludedFoldersDesc;

  /// No description provided for @addExcludedFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addExcludedFolder;

  /// No description provided for @noExcludedFolders.
  ///
  /// In en, this message translates to:
  /// **'No hidden folders.'**
  String get noExcludedFolders;

  /// No description provided for @externalOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the external file.'**
  String get externalOpenError;

  /// No description provided for @externalOpenNoPermission.
  ///
  /// In en, this message translates to:
  /// **'File permission denied. Cannot play external file.'**
  String get externalOpenNoPermission;

  /// No description provided for @waveformViewer.
  ///
  /// In en, this message translates to:
  /// **'Waveform View'**
  String get waveformViewer;

  /// No description provided for @waveformPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing waveform…'**
  String get waveformPreparing;

  /// No description provided for @waveformFirstTimeNote.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the track for the first time. Subsequent openings are instant.'**
  String get waveformFirstTimeNote;

  /// No description provided for @waveformUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Waveform could not be generated for this track.'**
  String get waveformUnavailable;

  /// No description provided for @waveformNoFilePath.
  ///
  /// In en, this message translates to:
  /// **'This track has no local file path. Waveform is only available for local files.'**
  String get waveformNoFilePath;

  /// No description provided for @widgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Widget'**
  String get widgetSettings;

  /// No description provided for @widgetTheme.
  ///
  /// In en, this message translates to:
  /// **'Widget Theme'**
  String get widgetTheme;

  /// No description provided for @widgetThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get widgetThemeSystem;

  /// No description provided for @widgetThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get widgetThemeLight;

  /// No description provided for @widgetThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get widgetThemeDark;

  /// No description provided for @widgetTransparency.
  ///
  /// In en, this message translates to:
  /// **'Transparent background'**
  String get widgetTransparency;

  /// No description provided for @widgetTransparencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a semi-transparent background instead of solid color'**
  String get widgetTransparencyDesc;

  /// No description provided for @addWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'Add the Resonance widget from your home screen\'s widget menu.'**
  String get addWidgetHint;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get homeGoodNight;

  /// No description provided for @homeNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get homeNowPlaying;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your music is silent'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi-res songs, tapes and studio masters on this device will appear here.'**
  String get homeEmptyMessage;

  /// No description provided for @homeScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan & start'**
  String get homeScanNow;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'What shall we play tonight?'**
  String get homeTagline;

  /// No description provided for @homeDiscoverAlbums.
  ///
  /// In en, this message translates to:
  /// **'Explore albums'**
  String get homeDiscoverAlbums;

  /// No description provided for @homeYourArtists.
  ///
  /// In en, this message translates to:
  /// **'Your artists'**
  String get homeYourArtists;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get homeFeatured;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover something new'**
  String get homeDiscover;

  /// No description provided for @homePlayAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play album'**
  String get homePlayAlbum;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupDesc.
  ///
  /// In en, this message translates to:
  /// **'Export your playlists, favorites, custom themes, equalizer presets and settings to a JSON file.'**
  String get backupDesc;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get backupImport;

  /// No description provided for @backupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully.'**
  String get backupExportSuccess;

  /// No description provided for @backupExportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup.'**
  String get backupExportError;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get backupImportSuccess;

  /// No description provided for @backupImportError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or corrupted backup file.'**
  String get backupImportError;

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite data?'**
  String get backupImportConfirmTitle;

  /// No description provided for @backupImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite existing playlists, favorites, themes, equalizer presets, and settings. This cannot be undone.'**
  String get backupImportConfirmMessage;

  /// No description provided for @backupOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Import & Overwrite'**
  String get backupOverwrite;

  /// No description provided for @backupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get backupCancel;

  /// No description provided for @backupVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'Backup version mismatch. Some data may not import.'**
  String get backupVersionMismatch;

  /// No description provided for @rewind10.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10s'**
  String get rewind10;

  /// No description provided for @forward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get forward10;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @homeMaster.
  ///
  /// In en, this message translates to:
  /// **'Master 24-Bit'**
  String get homeMaster;

  /// No description provided for @homeFeaturedSelection.
  ///
  /// In en, this message translates to:
  /// **'Featured Selection'**
  String get homeFeaturedSelection;

  /// No description provided for @homeOfflineEngine.
  ///
  /// In en, this message translates to:
  /// **'Offline Hi-Res Engine Active'**
  String get homeOfflineEngine;

  /// No description provided for @homeLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolving collection'**
  String get homeLoadingTitle;

  /// No description provided for @homeLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Scanning lossless metadata…'**
  String get homeLoadingMessage;

  /// No description provided for @homeLucky.
  ///
  /// In en, this message translates to:
  /// **'Lucky'**
  String get homeLucky;

  /// No description provided for @homeRandom10.
  ///
  /// In en, this message translates to:
  /// **'Random 10'**
  String get homeRandom10;

  /// No description provided for @homeLocalRecords.
  ///
  /// In en, this message translates to:
  /// **'Local records'**
  String get homeLocalRecords;

  /// No description provided for @homeFollowCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Following'**
  String homeFollowCount(int count);

  /// No description provided for @homePlayCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 plays} =1{1 play} other{{count} plays}}'**
  String homePlayCountBadge(int count);

  /// No description provided for @homeScanAndStart.
  ///
  /// In en, this message translates to:
  /// **'Scan & start'**
  String get homeScanAndStart;

  /// No description provided for @libraryLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get libraryLocal;

  /// No description provided for @libraryTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Tracks'**
  String libraryTracksCount(int count);

  /// No description provided for @libraryLosslessHint.
  ///
  /// In en, this message translates to:
  /// **'Lossless (FLAC/MP3)'**
  String get libraryLosslessHint;

  /// No description provided for @shuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle All'**
  String get shuffleAll;

  /// No description provided for @playInOrder.
  ///
  /// In en, this message translates to:
  /// **'Play in Order'**
  String get playInOrder;

  /// No description provided for @nowPlayingBadge.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get nowPlayingBadge;

  /// No description provided for @searchInLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Search in {count} audio files...'**
  String searchInLibraryHint(int count);

  /// No description provided for @rescanStorage.
  ///
  /// In en, this message translates to:
  /// **'Rescan Storage'**
  String get rescanStorage;

  /// No description provided for @libraryOptions.
  ///
  /// In en, this message translates to:
  /// **'Library Options'**
  String get libraryOptions;

  /// No description provided for @sortByTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get sortByTitleAsc;

  /// No description provided for @sortByArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get sortByArtist;

  /// No description provided for @sortByAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album Name'**
  String get sortByAlbum;

  /// No description provided for @sortByDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added (New)'**
  String get sortByDateAdded;

  /// No description provided for @sortByDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (Long-Short)'**
  String get sortByDuration;

  /// No description provided for @offlineCoreBadge.
  ///
  /// In en, this message translates to:
  /// **'v{version} • Offline Core'**
  String offlineCoreBadge(String version);

  /// No description provided for @themeAnimationLevel.
  ///
  /// In en, this message translates to:
  /// **'Animation level'**
  String get themeAnimationLevel;

  /// No description provided for @animFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get animFull;

  /// No description provided for @animReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get animReduced;

  /// No description provided for @animNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get animNone;

  /// No description provided for @settingsDescPlayback.
  ///
  /// In en, this message translates to:
  /// **'Seek intervals, headphone pause, ReplayGain and repeat'**
  String get settingsDescPlayback;

  /// No description provided for @settingsDescAudio.
  ///
  /// In en, this message translates to:
  /// **'Equalizer, loudness and audio effects'**
  String get settingsDescAudio;

  /// No description provided for @settingsDescLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scanning, excluded folders, minimum duration'**
  String get settingsDescLibrary;

  /// No description provided for @settingsDescTags.
  ///
  /// In en, this message translates to:
  /// **'Tag reading and album artwork'**
  String get settingsDescTags;

  /// No description provided for @settingsDescWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget appearance'**
  String get settingsDescWidget;

  /// No description provided for @settingsDescTheme.
  ///
  /// In en, this message translates to:
  /// **'Color, mode and custom themes'**
  String get settingsDescTheme;

  /// No description provided for @settingsDescFont.
  ///
  /// In en, this message translates to:
  /// **'Font family and scale'**
  String get settingsDescFont;

  /// No description provided for @settingsDescPlayerStyle.
  ///
  /// In en, this message translates to:
  /// **'Player visuals and animation level'**
  String get settingsDescPlayerStyle;

  /// No description provided for @settingsDescListStyle.
  ///
  /// In en, this message translates to:
  /// **'List and grid density'**
  String get settingsDescListStyle;

  /// No description provided for @settingsDescBackup.
  ///
  /// In en, this message translates to:
  /// **'Back up your data as a JSON file'**
  String get settingsDescBackup;

  /// No description provided for @settingsDescAbout.
  ///
  /// In en, this message translates to:
  /// **'Version info and licenses'**
  String get settingsDescAbout;

  /// No description provided for @settingsGroupContent.
  ///
  /// In en, this message translates to:
  /// **'Library & Content'**
  String get settingsGroupContent;

  /// No description provided for @settingsGroupSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsGroupSystem;

  /// No description provided for @settingsStatusSongs.
  ///
  /// In en, this message translates to:
  /// **'songs'**
  String get settingsStatusSongs;

  /// No description provided for @settingsStatusEqOn.
  ///
  /// In en, this message translates to:
  /// **'Equalizer on'**
  String get settingsStatusEqOn;

  /// No description provided for @settingsStatusEqOff.
  ///
  /// In en, this message translates to:
  /// **'Equalizer off'**
  String get settingsStatusEqOff;

  /// No description provided for @eqReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get eqReset;

  /// No description provided for @eqBandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bands'**
  String get eqBandsTitle;

  /// No description provided for @eqBandsUnit.
  ///
  /// In en, this message translates to:
  /// **'bands'**
  String get eqBandsUnit;

  /// No description provided for @themeColorSource.
  ///
  /// In en, this message translates to:
  /// **'Color source'**
  String get themeColorSource;

  /// No description provided for @themeSourceSeed.
  ///
  /// In en, this message translates to:
  /// **'Custom seed'**
  String get themeSourceSeed;

  /// No description provided for @themeSourceSystem.
  ///
  /// In en, this message translates to:
  /// **'Material You'**
  String get themeSourceSystem;

  /// No description provided for @themeSourceArtwork.
  ///
  /// In en, this message translates to:
  /// **'From artwork'**
  String get themeSourceArtwork;

  /// No description provided for @themePresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset palettes'**
  String get themePresetsTitle;

  /// No description provided for @themeCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get themeCustomTitle;

  /// No description provided for @themeCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom themes yet. Create one with +.'**
  String get themeCustomEmpty;

  /// No description provided for @themeAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced theme settings'**
  String get themeAdvancedSettings;

  /// No description provided for @themeImportTheme.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get themeImportTheme;

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Theme imported'**
  String get themeImported;

  /// No description provided for @themeImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid theme file'**
  String get themeImportInvalid;

  /// No description provided for @themeScheduledDark.
  ///
  /// In en, this message translates to:
  /// **'Scheduled dark mode'**
  String get themeScheduledDark;

  /// No description provided for @themeScheduledDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Switches to dark mode between the hours you set'**
  String get themeScheduledDarkDesc;

  /// No description provided for @themeExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the theme file'**
  String get themeExportFailed;

  /// No description provided for @backupNoAudioNote.
  ///
  /// In en, this message translates to:
  /// **'Music files (.flac, .mp3) are not included in the backup'**
  String get backupNoAudioNote;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get sleepTimerRemaining;

  /// No description provided for @sleepTimerAddFive.
  ///
  /// In en, this message translates to:
  /// **'Add 5 min'**
  String get sleepTimerAddFive;

  /// No description provided for @settingsRowAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance & theme'**
  String get settingsRowAppearance;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String hoursShort(int hours);

  /// No description provided for @queueLocalChip.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get queueLocalChip;

  /// No description provided for @queueSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} • {duration}'**
  String queueSummary(int count, String duration);

  /// No description provided for @queueUpNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get queueUpNextTitle;

  /// No description provided for @queueRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemoveAction;

  /// No description provided for @swipeUpToSeeQueue.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to see the queue'**
  String get swipeUpToSeeQueue;

  /// No description provided for @albumDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Album Details'**
  String get albumDetailTitle;

  /// No description provided for @albumTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get albumTracksTitle;

  /// No description provided for @backupIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Included in the backup'**
  String get backupIncludedTitle;

  /// No description provided for @backupIncludedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data exported to the backup file'**
  String get backupIncludedSubtitle;

  /// No description provided for @backupItemPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get backupItemPlaylists;

  /// No description provided for @backupItemPlaylistsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your playlists and the songs in them'**
  String get backupItemPlaylistsDesc;

  /// No description provided for @backupItemFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get backupItemFavorites;

  /// No description provided for @backupItemFavoritesDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs you marked as favorite'**
  String get backupItemFavoritesDesc;

  /// No description provided for @backupItemThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get backupItemThemes;

  /// No description provided for @backupItemThemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Your created color and interface themes'**
  String get backupItemThemesDesc;

  /// No description provided for @backupItemEqualizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer presets'**
  String get backupItemEqualizer;

  /// No description provided for @backupItemEqualizerDesc.
  ///
  /// In en, this message translates to:
  /// **'Custom EQ and DSP sound profiles'**
  String get backupItemEqualizerDesc;

  /// No description provided for @backupItemSettings.
  ///
  /// In en, this message translates to:
  /// **'App & player settings'**
  String get backupItemSettings;

  /// No description provided for @backupItemSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Preferences, language and audio configuration'**
  String get backupItemSettingsDesc;

  /// No description provided for @backupCreateFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create backup file'**
  String get backupCreateFileTitle;

  /// No description provided for @backupFormatNote.
  ///
  /// In en, this message translates to:
  /// **'Format: .json'**
  String get backupFormatNote;

  /// No description provided for @backupLastExport.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backupLastExport(String date);

  /// No description provided for @backupRestorePickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick a file and restore'**
  String get backupRestorePickFile;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFilterAll;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result found} other{{count} results found}}'**
  String searchResultCount(int count);

  /// No description provided for @searchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchHistoryTitle;

  /// No description provided for @permissionMediaSpec.
  ///
  /// In en, this message translates to:
  /// **'READ_MEDIA_AUDIO'**
  String get permissionMediaSpec;

  /// No description provided for @folderHierarchyLabel.
  ///
  /// In en, this message translates to:
  /// **'Directory hierarchy'**
  String get folderHierarchyLabel;

  /// No description provided for @folderPlay.
  ///
  /// In en, this message translates to:
  /// **'Play folder'**
  String get folderPlay;

  /// No description provided for @folderHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get folderHide;

  /// No description provided for @folderHideConfirm.
  ///
  /// In en, this message translates to:
  /// **'This folder will be excluded from library scans. Continue?'**
  String get folderHideConfirm;

  /// No description provided for @folderHiddenToast.
  ///
  /// In en, this message translates to:
  /// **'Folder hidden from library'**
  String get folderHiddenToast;

  /// No description provided for @folderUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get folderUndo;

  /// No description provided for @folderSummary.
  ///
  /// In en, this message translates to:
  /// **'{folders, plural, =1{1 folder} other{{folders} folders}} • {songs, plural, =1{1 song} other{{songs} songs}} • {duration}'**
  String folderSummary(int folders, int songs, String duration);

  /// No description provided for @genreDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Genre Details'**
  String get genreDetailTitle;

  /// No description provided for @genrePlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play Genre Tracks'**
  String get genrePlayAll;

  /// No description provided for @genreAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums in This Genre'**
  String get genreAlbumsTitle;

  /// No description provided for @artistProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist Profile'**
  String get artistProfileTitle;

  /// No description provided for @artistPopularTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Songs'**
  String get artistPopularTitle;

  /// No description provided for @artistMostPlayedHint.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get artistMostPlayedHint;

  /// No description provided for @artistAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbumsTitle;

  /// No description provided for @artistSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar Local Artists'**
  String get artistSimilarTitle;

  /// No description provided for @artistSimilarHint.
  ///
  /// In en, this message translates to:
  /// **'From your library'**
  String get artistSimilarHint;

  /// No description provided for @artistOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'All tracks by this artist are stored on your device, fully offline.'**
  String get artistOfflineNote;

  /// No description provided for @statsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get statsPeriodWeek;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get statsPeriodAll;

  /// No description provided for @statsTotalListen.
  ///
  /// In en, this message translates to:
  /// **'Total Listening Time'**
  String get statsTotalListen;

  /// No description provided for @statsWeeklyChart.
  ///
  /// In en, this message translates to:
  /// **'Listening Habits'**
  String get statsWeeklyChart;

  /// No description provided for @statsWeeklyPeak.
  ///
  /// In en, this message translates to:
  /// **'Weekly peak: {day} ({count, plural, =1{1 play} other{{count} plays}})'**
  String statsWeeklyPeak(String day, int count);

  /// No description provided for @statsDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get statsDayMon;

  /// No description provided for @statsDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get statsDayTue;

  /// No description provided for @statsDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get statsDayWed;

  /// No description provided for @statsDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get statsDayThu;

  /// No description provided for @statsDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get statsDayFri;

  /// No description provided for @statsDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get statsDaySat;

  /// No description provided for @statsDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get statsDaySun;

  /// No description provided for @statsSharePct.
  ///
  /// In en, this message translates to:
  /// **'%{pct} share'**
  String statsSharePct(int pct);

  /// No description provided for @statsTopTracks.
  ///
  /// In en, this message translates to:
  /// **'Most Played Songs'**
  String get statsTopTracks;

  /// No description provided for @statsRecent24h.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get statsRecent24h;

  /// No description provided for @statsRelNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get statsRelNow;

  /// No description provided for @statsRelMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String statsRelMinutes(int n);

  /// No description provided for @statsRelHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String statsRelHours(int n);

  /// No description provided for @statsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Local & Private'**
  String get statsPrivacyTitle;

  /// No description provided for @statsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All statistics are stored locally on your device; no data is ever uploaded.'**
  String get statsPrivacyBody;

  /// No description provided for @optionsQueuedNext.
  ///
  /// In en, this message translates to:
  /// **'Added to play next'**
  String get optionsQueuedNext;

  /// No description provided for @optionsAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get optionsAddedToQueue;

  /// No description provided for @optionsFavAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get optionsFavAdded;

  /// No description provided for @optionsFavRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get optionsFavRemoved;

  /// No description provided for @optionsShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share the file directly'**
  String get optionsShareHint;

  /// No description provided for @optionsMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed File Info'**
  String get optionsMetaTitle;

  /// No description provided for @optionsMetaFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get optionsMetaFormat;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @optionsPathCopied.
  ///
  /// In en, this message translates to:
  /// **'File path copied to clipboard'**
  String get optionsPathCopied;

  /// No description provided for @sleepPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset Durations'**
  String get sleepPresetsTitle;

  /// No description provided for @sleepCustomChip.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sleepCustomChip;

  /// No description provided for @sleepCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Duration'**
  String get sleepCustomTitle;

  /// No description provided for @sleepStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get sleepStartAction;

  /// No description provided for @sleepTimerActiveNote.
  ///
  /// In en, this message translates to:
  /// **'Music will fade out softly and stop when the timer ends.'**
  String get sleepTimerActiveNote;

  /// No description provided for @sleepStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop Timer'**
  String get sleepStopAction;

  /// No description provided for @sleepFadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fade Out'**
  String get sleepFadeTitle;

  /// No description provided for @sleepFadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Lower the volume gradually so sleep is not disturbed.'**
  String get sleepFadeDesc;

  /// No description provided for @sleepFadeWindow.
  ///
  /// In en, this message translates to:
  /// **'Fade Window'**
  String get sleepFadeWindow;

  /// No description provided for @notifPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications let the player show media controls and the sleep timer status outside the app.'**
  String get notifPermissionHint;

  /// No description provided for @sleepTimerEndOfTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'Playback ends gently when the current track finishes.'**
  String get sleepTimerEndOfTrackDesc;

  /// No description provided for @externalTitle.
  ///
  /// In en, this message translates to:
  /// **'External File'**
  String get externalTitle;

  /// No description provided for @externalTempNote.
  ///
  /// In en, this message translates to:
  /// **'Temporary source'**
  String get externalTempNote;

  /// No description provided for @externalSourceBadge.
  ///
  /// In en, this message translates to:
  /// **'External Source'**
  String get externalSourceBadge;

  /// No description provided for @externalSpecsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Stream Properties'**
  String get externalSpecsTitle;

  /// No description provided for @externalAddLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get externalAddLibrary;

  /// No description provided for @externalScanDone.
  ///
  /// In en, this message translates to:
  /// **'Library scan finished'**
  String get externalScanDone;

  /// No description provided for @settingsRowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Lock Screen'**
  String get settingsRowNotifications;

  /// No description provided for @settingsDescNotifications.
  ///
  /// In en, this message translates to:
  /// **'Media notification and lock screen preview'**
  String get settingsDescNotifications;

  /// No description provided for @notifPreviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Android draws the media notification itself; this preview reflects your real playback state.'**
  String get notifPreviewIntro;

  /// No description provided for @notifSleepActive.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer Active'**
  String get notifSleepActive;

  /// No description provided for @notifSleepFadesIn.
  ///
  /// In en, this message translates to:
  /// **'Audio fades out in {time}'**
  String notifSleepFadesIn(String time);

  /// No description provided for @notifSleepHint.
  ///
  /// In en, this message translates to:
  /// **'Set a sleep timer to fade playback gently.'**
  String get notifSleepHint;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextTrack;

  /// No description provided for @stateFoldersAction.
  ///
  /// In en, this message translates to:
  /// **'Add Folders / Check Permissions'**
  String get stateFoldersAction;

  /// No description provided for @statePathHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended download path'**
  String get statePathHintTitle;

  /// No description provided for @stateFormatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supported Offline Formats'**
  String get stateFormatsTitle;

  /// No description provided for @stateNoLyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Lyrics Found'**
  String get stateNoLyricsTitle;

  /// No description provided for @stateNoLyricsMessage.
  ///
  /// In en, this message translates to:
  /// **'Lyrics display is not available in this version yet.'**
  String get stateNoLyricsMessage;

  /// No description provided for @stateSuggestedLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested artists'**
  String get stateSuggestedLabel;

  /// No description provided for @widgetPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get widgetPreviewLabel;

  /// No description provided for @widgetSizeBadge.
  ///
  /// In en, this message translates to:
  /// **'4 × 1'**
  String get widgetSizeBadge;

  /// No description provided for @widgetNativeNote.
  ///
  /// In en, this message translates to:
  /// **'The widget is drawn by the Android launcher via RemoteViews; changes apply within a few seconds.'**
  String get widgetNativeNote;

  /// No description provided for @miniPlayerShow.
  ///
  /// In en, this message translates to:
  /// **'Show mini player'**
  String get miniPlayerShow;

  /// No description provided for @autoSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get autoSongs;

  /// No description provided for @autoAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get autoAlbums;

  /// No description provided for @autoArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get autoArtists;

  /// No description provided for @autoGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get autoGenres;

  /// No description provided for @autoPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get autoPlaylists;

  /// No description provided for @autoFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get autoFavorites;

  /// No description provided for @autoFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get autoFolders;

  /// No description provided for @autoBackupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get autoBackupSectionTitle;

  /// No description provided for @autoBackupSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your playlists, favorites, themes, equalizer presets and settings are backed up to the app folder on a schedule. Audio files are not included.'**
  String get autoBackupSectionDesc;

  /// No description provided for @autoBackupSwitch.
  ///
  /// In en, this message translates to:
  /// **'Back up automatically'**
  String get autoBackupSwitch;

  /// No description provided for @autoBackupFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get autoBackupFrequencyLabel;

  /// No description provided for @autoBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get autoBackupDaily;

  /// No description provided for @autoBackupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get autoBackupWeekly;

  /// No description provided for @autoBackupKeep.
  ///
  /// In en, this message translates to:
  /// **'Backups to keep'**
  String get autoBackupKeep;

  /// No description provided for @autoBackupRunNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get autoBackupRunNow;

  /// No description provided for @autoBackupLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last automatic backup: {time}'**
  String autoBackupLastRun(String time);

  /// No description provided for @autoBackupNeverRun.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup yet'**
  String get autoBackupNeverRun;

  /// No description provided for @autoBackupListTitle.
  ///
  /// In en, this message translates to:
  /// **'Stored backups'**
  String get autoBackupListTitle;

  /// No description provided for @autoBackupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stored backups yet'**
  String get autoBackupEmpty;

  /// No description provided for @autoBackupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get autoBackupRestoreConfirmTitle;

  /// No description provided for @autoBackupRestoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Current playlists, favorites, themes, equalizer presets and settings will be replaced with the backup from {time}. This cannot be undone.'**
  String autoBackupRestoreConfirmMessage(String time);

  /// No description provided for @autoBackupRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get autoBackupRestoreDone;

  /// No description provided for @autoBackupRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get autoBackupRestoreError;

  /// No description provided for @autoBackupDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get autoBackupDeleteConfirmTitle;

  /// No description provided for @autoBackupDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The backup file will be permanently removed.'**
  String get autoBackupDeleteConfirmMessage;

  /// No description provided for @autoBackupDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get autoBackupDelete;

  /// No description provided for @autoBackupDeleteDone.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get autoBackupDeleteDone;

  /// No description provided for @autoBackupRunDone.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup created'**
  String get autoBackupRunDone;

  /// No description provided for @autoBackupRunError.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get autoBackupRunError;

  /// No description provided for @autoBackupSize.
  ///
  /// In en, this message translates to:
  /// **'{kb} KB'**
  String autoBackupSize(int kb);
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
