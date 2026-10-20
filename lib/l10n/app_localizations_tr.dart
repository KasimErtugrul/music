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
}
