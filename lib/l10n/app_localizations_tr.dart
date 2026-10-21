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
  String get spikeLoadError => 'İstatistikler yüklenemedi';

  @override
  String get spikeNotScanned => 'Henüz taranmadı';

  @override
  String get spikeEmpty => 'Öğe bulunamadı';

  @override
  String get nowPlaying => 'Şu an çalıyor';

  @override
  String get playerTitle => 'Oynatıcı';

  @override
  String get playerNoSong => 'Şu an çalan bir şarkı yok';

  @override
  String get backToParent => 'Geri';
}
