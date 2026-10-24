// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Resonance';

  @override
  String get tabHome => 'Ana Sayfa';

  @override
  String get tabLibrary => 'Kütüphane';

  @override
  String get tabPlaylists => 'Playlist\'ler';

  @override
  String get tabSearch => 'Ara';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get libraryTabSongs => 'Şarkılar';

  @override
  String get libraryTabAlbums => 'Albümler';

  @override
  String get libraryTabArtists => 'Sanatçılar';

  @override
  String get libraryTabGenres => 'Türler';

  @override
  String get libraryTabFolders => 'Klasörler';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonClose => 'Kapat';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      zero: 'Şarkı yok',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albüm',
      zero: 'Albüm yok',
    );
    return '$_temp0';
  }

  @override
  String get debugLanguageToggle => 'Dili değiştir (geçici)';

  @override
  String get permissionTitle => 'Çevrimdışı müzik çalar';

  @override
  String get permissionSubtitle =>
      'Cihazınızdaki müzik dosyalarını çalabilmek için ses dosyalarına erişim izni gerekir.';

  @override
  String get permissionMediaTitle => 'Müzik ve ses dosyaları';

  @override
  String get permissionMediaDescription =>
      'Yerel kütüphanenizdeki şarkıları listelemek ve çalmak için gereklidir.';

  @override
  String get permissionGrantButton => 'İzin ver';

  @override
  String get permissionGrantedLabel => 'İzin verildi';

  @override
  String get permissionDeniedTitle => 'İzin reddedildi';

  @override
  String get permissionDeniedDescription =>
      'Müzik dosyalarına erişim olmadan kütüphaneniz oluşturulamaz. Tekrar deneyebilirsiniz.';

  @override
  String get permissionPermanentlyDeniedTitle =>
      'İzin kalıcı olarak reddedildi';

  @override
  String get permissionPermanentlyDeniedDescription =>
      'Erişim engellendi. Müziklerinizi çalabilmek için uygulama ayarlarından manuel olarak izin vermeniz gerekir.';

  @override
  String get permissionOpenSettingsButton => 'Uygulama ayarlarına git';

  @override
  String get permissionContinueButton => 'Devam et';

  @override
  String get permissionNotificationTitle => 'Bildirim izni';

  @override
  String get permissionNotificationBadge => 'Android 13+';

  @override
  String get permissionNotificationDescription =>
      'İsteğe bağlı. Kilit ekranında ve bildirim panelinde çalma kontrollerini gösterir. İzin verilmezse çalma etkilenmez.';

  @override
  String get permissionPrivacyTitle => 'Gizlilik ve çevrimdışı taahhüt';

  @override
  String get permissionPrivacyBody =>
      'Resonance hiçbir zaman internet bağlantısı kurmaz. Verileriniz bu cihazda kalır, hiçbir ağa gönderilmez.';

  @override
  String get unknownArtist => 'Bilinmeyen sanatçı';

  @override
  String get unknownAlbum => 'Bilinmeyen albüm';

  @override
  String get unknownGenre => 'Bilinmeyen tür';

  @override
  String get sortBy => 'Sırala';

  @override
  String get sortFieldTitle => 'Ad';

  @override
  String get sortFieldArtist => 'Sanatçı';

  @override
  String get sortFieldAlbum => 'Albüm';

  @override
  String get sortFieldDateAdded => 'Eklenme tarihi';

  @override
  String get sortFieldDuration => 'Süre';

  @override
  String get sortAscending => 'Artan';

  @override
  String get sortDescending => 'Azalan';

  @override
  String get libraryEmptySongsTitle => 'Şarkı bulunamadı';

  @override
  String get libraryEmptySongsMessage =>
      'Kütüphanenizde henüz şarkı yok. Cihazınızda müzik dosyaları olduğundan emin olun.';

  @override
  String get libraryEmptyAlbumsTitle => 'Albüm yok';

  @override
  String get libraryEmptyAlbumsMessage =>
      'Kütüphane tarandığında albümler burada görünecek.';

  @override
  String get libraryEmptyArtistsTitle => 'Sanatçı yok';

  @override
  String get libraryEmptyArtistsMessage =>
      'Kütüphane tarandığında sanatçılar burada görünecek.';

  @override
  String get libraryEmptyGenresTitle => 'Tür yok';

  @override
  String get libraryEmptyGenresMessage =>
      'Kütüphane tarandığında türler burada görünecek.';

  @override
  String get libraryEmptyFoldersTitle => 'Müzik klasörü yok';

  @override
  String get libraryEmptyFoldersMessage =>
      'Müzik içeren klasörler burada görünecek.';

  @override
  String get libraryLoadErrorTitle => 'Kütüphane yüklenemedi';

  @override
  String get libraryLoadErrorMessage => 'Kütüphane okunurken bir hata oluştu.';

  @override
  String get folderRootName => 'Depolama';

  @override
  String get folderSubfoldersTitle => 'Alt klasörler';

  @override
  String get folderSongsTitle => 'Bu klasördeki şarkılar';

  @override
  String get spikeTitle => 'Spike Test Sayfası';

  @override
  String get spikeOpenButton => 'Spike Testini Aç';

  @override
  String get spikeScanButton => 'Kütüphaneyi Tara';

  @override
  String spikeStats(int total, int elapsed) {
    return 'İstatistik: $total şarkı ($elapsed ms)';
  }

  @override
  String spikeMissingStats(int noArtist, int noGenre) {
    return 'Sanatçısı yok: $noArtist, türü yok: $noGenre';
  }

  @override
  String get spikeLoadError => 'İstatistikler yüklenemedi';

  @override
  String get spikeNotScanned => 'Henüz taranmadı';

  @override
  String get spikeEmpty => 'Öğe bulunamadı';

  @override
  String get backToParent => 'Geri';

  @override
  String get nowPlaying => 'Şu an çalıyor';

  @override
  String get playerTitle => 'Oynatıcı';

  @override
  String get playerNoSong => 'Şu an çalan bir şarkı yok';

  @override
  String get playlistsTitle => 'Playlist\'ler';

  @override
  String get createPlaylist => 'Yeni playlist';

  @override
  String get playlistNameLabel => 'Playlist adı';

  @override
  String get renamePlaylist => 'Yeniden adlandır';

  @override
  String get deletePlaylist => 'Playlist\'i sil';

  @override
  String get deletePlaylistConfirm =>
      'Bu playlist\'i silmek istediğinize emin misiniz?';

  @override
  String get addToPlaylist => 'Playlist\'e ekle';

  @override
  String get noPlaylists => 'Henüz playlist yok';

  @override
  String get noPlaylistsMessage =>
      'İlk listenizi oluşturmak için + butonuna dokunun.';

  @override
  String get playlistEmpty => 'Bu playlist boş';

  @override
  String get queueTitle => 'Kuyruk';

  @override
  String get playNext => 'Sonra çal';

  @override
  String get addToQueue => 'Kuyruğa ekle';

  @override
  String get queueEmpty => 'Kuyruk boş';

  @override
  String get clearQueue => 'Kuyruğu temizle';

  @override
  String get clearQueueConfirm =>
      'Kuyruğu temizlemek istediğinize emin misiniz?';

  @override
  String get queueCleared => 'Kuyruk temizlendi';

  @override
  String get favorites => 'Favoriler';

  @override
  String get history => 'Geçmiş';

  @override
  String get addToFavorites => 'Favorilere ekle';

  @override
  String get removeFromFavorites => 'Favorilerden çıkar';

  @override
  String get favoritesEmpty => 'Henüz favori yok';

  @override
  String get historyEmpty => 'Henüz geçmiş yok';

  @override
  String get clearHistory => 'Geçmişi temizle';

  @override
  String get clearHistoryConfirm =>
      'Çalma geçmişinizi temizlemek istediğinize emin misiniz?';

  @override
  String get smartPlaylists => 'Akıllı Listeler';

  @override
  String get recentlyAdded => 'Son Eklenenler';

  @override
  String get mostPlayed => 'En Çok Çalınanlar';

  @override
  String get neverPlayed => 'Hiç Çalınmayanlar';

  @override
  String get statsTitle => 'İstatistikler';

  @override
  String get totalPlays => 'Toplam çalma';

  @override
  String get uniqueSongsPlayed => 'Çalınan benzersiz şarkı';

  @override
  String get topArtists => 'En Çok Dinlenen Sanatçılar';

  @override
  String get topGenres => 'En Çok Dinlenen Türler';

  @override
  String get noStatsYet => 'Henüz yeterli dinleme verisi yok';

  @override
  String playCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kez çalındı',
      zero: '0 kez çalındı',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Şarkı, albüm, sanatçı ara...';

  @override
  String get searchEmptyTitle => 'Sonuç bulunamadı';

  @override
  String get searchEmptyMessage => 'Farklı bir arama terimi deneyin.';

  @override
  String get noSearchYet => 'Aramaya başlamak için bir şeyler yazın.';

  @override
  String get share => 'Paylaş';

  @override
  String get songInfo => 'Şarkı Bilgisi';

  @override
  String get infoTitle => 'Ad';

  @override
  String get infoArtist => 'Sanatçı';

  @override
  String get infoAlbum => 'Albüm';

  @override
  String get infoGenre => 'Tür';

  @override
  String get infoDuration => 'Süre';

  @override
  String get infoPath => 'Dosya Yolu';

  @override
  String get infoSize => 'Dosya Boyutu';

  @override
  String get infoDateAdded => 'Eklenme Tarihi';

  @override
  String get searchResults => 'Arama Sonuçları';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSystem => 'Sistem';

  @override
  String get settingsThemeMode => 'Tema modu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsDynamicColor => 'Dinamik renk';

  @override
  String get settingsDynamicColorDescription =>
      'Android 12+ Material You renklerini kullan';

  @override
  String get settingsAmoledDark => 'AMOLED siyah';

  @override
  String get settingsAmoledDarkDescription =>
      'Koyu modda tam siyah yüzeyler kullan';

  @override
  String get settingsGroupGeneral => 'Genel';

  @override
  String get settingsGroupAppearance => 'Görünüm';

  @override
  String get settingsSearchHint => 'Ayarlarda ara';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String settingsVersionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String get settingsAboutDescription =>
      'Resonance, Android için çevrimdışı bir müzik çalardır. Verileriniz bu cihazdan asla ayrılmaz.';

  @override
  String get settingsLicenses => 'Açık kaynak lisansları';

  @override
  String get themeDefault => 'Varsayılan';

  @override
  String themePresetName(String name) {
    return 'Hazır tema: $name';
  }

  @override
  String get themeCustom => 'Özel';

  @override
  String get themePresetDynamic => 'Dinamik (Material You)';

  @override
  String get themePresetFromArtwork => 'Kapaktan renk';

  @override
  String get themePresetSeed => 'Özel tohum rengi';

  @override
  String get themeAmoledOn => 'AMOLED siyah yüzeyler';

  @override
  String get themeHighContrast => 'Yüksek kontrast';

  @override
  String get themeSurfaceTint => 'Yüzey tonlaması';

  @override
  String get themeRoundedCorners => 'Yuvarlak köşeler';

  @override
  String get themeDensity => 'Bileşen yoğunluğu';

  @override
  String get themeDensityCompact => 'Sıkı';

  @override
  String get themeDensityStandard => 'Normal';

  @override
  String get themeDensityComfortable => 'Ferah';

  @override
  String get themeFont => 'Yazı tipi';

  @override
  String get themeFontDefault => 'Varsayılan';

  @override
  String get themeTextScale => 'Yazı ölçeği';

  @override
  String get playerBackgroundSolid => 'Düz renk';

  @override
  String get playerBackgroundGradient => 'Kapaktan gradyan';

  @override
  String get playerBackgroundBlur => 'Bulanık kapak';

  @override
  String get playerArtworkSquare => 'Kare';

  @override
  String get playerArtworkRounded => 'Yuvarlak köşe';

  @override
  String get playerArtworkCircle => 'Daire';

  @override
  String get listViewCompact => 'Sıkı';

  @override
  String get listViewComfortable => 'Rahat';

  @override
  String get listViewGrid => 'Izgara';

  @override
  String get animationsFull => 'Tam';

  @override
  String get animationsReduced => 'Azaltılmış';

  @override
  String get animationsNone => 'Kapalı';

  @override
  String get themeGroupPlayer => 'Oynatıcı';

  @override
  String get themeGroupList => 'Kütüphane listesi';

  @override
  String get themeGroupAnimation => 'Animasyonlar';

  @override
  String get themeGroupFont => 'Yazı tipi';

  @override
  String get themeGroupShape => 'Şekil ve yoğunluk';

  @override
  String get themeGroupColor => 'Renk';

  @override
  String get themeGroupMode => 'Tema modu';

  @override
  String get themeGroupDarkVariant => 'Koyu varyant';

  @override
  String get themeDarkNormal => 'Normal koyu';

  @override
  String get themeDarkAmoled => 'AMOLED siyah';

  @override
  String get themeSeedColor => 'Tohum rengi';

  @override
  String get themeResetToDefault => 'Varsayılana sıfırla';

  @override
  String get themeResetConfirm =>
      'Tüm görünüm ayarları varsayılana sıfırlansın mı?';

  @override
  String get themePlayerTitle => 'Oynatıcı görünümü';

  @override
  String get themeListTitle => 'Kütüphane listesi görünümü';

  @override
  String get themePreviewTitle => 'Önizleme';

  @override
  String get themePreviewSongTitle => 'Örnek Şarkı';

  @override
  String get themePreviewSongArtist => 'Örnek Sanatçı';

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsStorage => 'Storage & Advanced';

  @override
  String get settingsQueue => 'Queue & Playlist';

  @override
  String get seekInterval => 'Seek interval';

  @override
  String seekIntervalValue(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get autoResume => 'Auto-resume on app start';

  @override
  String get pauseOnHeadphone => 'Pause when headphones disconnected';

  @override
  String get defaultShuffle => 'Default shuffle';

  @override
  String get defaultRepeat => 'Default repeat mode';

  @override
  String get repeatNone => 'None';

  @override
  String get repeatAll => 'All';

  @override
  String get repeatOne => 'One';

  @override
  String get minDuration => 'Minimum song duration';

  @override
  String get scanOnStartup => 'Scan library on startup';

  @override
  String get resetGroup => 'Reset group to defaults';

  @override
  String get resetAll => 'Reset all settings';

  @override
  String get resetConfirm =>
      'Are you sure you want to reset all settings to their defaults? This cannot be undone.';

  @override
  String get textScale => 'Text scale';

  @override
  String get reduceAnimations => 'Reduce animations';

  @override
  String get largeTouchTargets => 'Large touch targets';

  @override
  String get audioSettingsTitle => 'Ses';

  @override
  String get equalizerTitle => 'Ekolayzer';

  @override
  String get equalizerEnable => 'Ekolayzeri Etkinleştir';

  @override
  String get equalizerPresets => 'Ön Ayarlar';

  @override
  String get equalizerSavePreset => 'Ön Ayar Kaydet';

  @override
  String get equalizerPresetName => 'Ön Ayar Adı';

  @override
  String get loudnessEnhancer => 'Ses Yüksekliği Artırıcı';

  @override
  String get loudnessGain => 'Kazanç';

  @override
  String get equalizerNoBands => 'Ekolayzer bu cihazda desteklenmiyor.';

  @override
  String get eqPresetFlat => 'Nötr';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Klasik';

  @override
  String get eqPresetBass => 'Bas Artırıcı';

  @override
  String get eqPresetTreble => 'Tiz Artırıcı';

  @override
  String get eqPresetVocal => 'Vokal';

  @override
  String get eqGroupBuiltIn => 'Hazır Ön Ayarlar';

  @override
  String get eqGroupCustom => 'Özel Ön Ayarlar';

  @override
  String get playbackSpeedPitch => 'Hız ve Pitch';

  @override
  String get playbackSpeed => 'Hız';

  @override
  String get playbackPitch => 'Pitch';

  @override
  String get playbackReset => 'Sıfırla';

  @override
  String get sleepTimer => 'Uyku Zamanlayıcısı';

  @override
  String get sleepTimerOff => 'Kapalı';

  @override
  String get sleepTimerEndOfTrack => 'Şarkı bitince';

  @override
  String sleepTimerSetFor(int minutes) {
    return 'Zamanlayıcı $minutes dk olarak ayarlandı';
  }

  @override
  String get sleepTimerEndOfTrackSet => 'Bu şarkıdan sonra duracak';

  @override
  String get gaplessPlayback => 'Gapless oynatma';

  @override
  String get skipSilence => 'Sessizliği atla';

  @override
  String minutesShort(int minutes) {
    return '$minutes dk';
  }

  @override
  String get tagViewer => 'Etiket Bilgisi';

  @override
  String get tagTitle => 'Başlık';

  @override
  String get tagArtist => 'Sanatçı';

  @override
  String get tagAlbum => 'Albüm';

  @override
  String get tagGenre => 'Tür';

  @override
  String get tagYear => 'Yıl';

  @override
  String get tagReadOnlyNote =>
      'Etiketler salt-okunurdur. Düzenlemek için cihazınızın dosya yöneticisini kullanın.';

  @override
  String get tagReadError => 'Etiketler okunamadı.';

  @override
  String get replayGain => 'ReplayGain';

  @override
  String get replayGainEnable => 'ReplayGain Uygula';

  @override
  String get replayGainEnableDesc =>
      'Şarkı ses yüksekliği etiketlerine göre sesi normalize eder';

  @override
  String get tagsArtworkSettings => 'Etiket ve Kapak';

  @override
  String get clearArtworkCache => 'Kapak önbelleğini temizle';

  @override
  String get artworkCacheCleared => 'Kapak önbelleği temizlendi';

  @override
  String get seekBarStyle => 'Seek Bar Stili';

  @override
  String get seekBarClassic => 'Klasik';

  @override
  String get seekBarThin => 'İnce';

  @override
  String get seekBarWaveform => 'Dalga Formu';

  @override
  String get excludedFolders => 'Gizli Klasörler';

  @override
  String get excludedFoldersDesc => 'Kütüphaneden hariç tutulan klasörler';

  @override
  String get addExcludedFolder => 'Klasör Ekle';

  @override
  String get noExcludedFolders => 'Gizli klasör yok.';

  @override
  String get externalOpenError => 'Harici dosya açılamadı.';

  @override
  String get externalOpenNoPermission =>
      'Dosya izni reddedildi. Harici dosya oynatılamıyor.';

  @override
  String get waveformViewer => 'Dalga Formu Görünümü';

  @override
  String get waveformPreparing => 'Dalga formu hazırlanıyor…';

  @override
  String get waveformFirstTimeNote =>
      'Şarkı ilk kez analiz ediliyor. Sonraki açılışlar anlık olur.';

  @override
  String get waveformUnavailable => 'Bu şarkı için dalga formu oluşturulamadı.';

  @override
  String get waveformNoFilePath =>
      'Bu şarkının yerel dosya yolu yok. Dalga formu yalnızca yerel dosyalar için kullanılabilir.';
}
