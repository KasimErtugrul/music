import 'package:flutter/material.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/pages/backup_page.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/font_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/list_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/player_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_gallery_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/audio_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/excluded_folders_page.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/tags_artwork_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/widget_settings_page.dart';

/// Ayar girdisinin arayüzdeki yeri.
///
/// - general   : ana ayar ekranında satır-içi düzenlenir (ör. dil).
/// - navigation: dokununca bir ayar sayfası açılır.
/// - appearance: görünüm/tema alanına ait sayfa girdileri.
enum SettingsGroup { general, navigation, appearance }

class SettingsEntry {
  const SettingsEntry({
    required this.key,
    required this.group,
    required this.title,
    this.pageBuilder,
  });

  final String key;
  final SettingsGroup group;

  /// Başlık, l10n anahtarı ADINDAN değil doğrudan çeviri fonksiyonundan
  /// okunur: (a) arama, bağlam-sız AppLocalizationsEn/Tr örnekleriyle hem
  /// Türkçe hem İngilizce başlıkta eşleyebilir; (b) yeni girdi eklemek için
  /// arama denetleyicisindeki switch'i güncellemek gerekmez.
  final String Function(AppLocalizations l10n) title;

  /// Dokunulunca açılacak sayfa. GetX'te sayfa builder ile açılır
  /// (Get.to(() => const Page())); isimli rota zorunlu değildir. Null ise
  /// girdi ana ayar ekranında satır-içi düzenlenir (ör. dil seçimi).
  final Widget Function()? pageBuilder;
}

/// Görev 4.2: uygulamanın GERÇEK ayar haritası.
///
/// Eskiden yalnızca 4 girdi vardı ve üçü hiçbir ekrana bağlanmayan ölü
/// kayıtlardı (themeMode / dynamicColor / amoledDark); arama pratikte
/// yalnızca Dil ayarını bulabiliyordu. Artık dizin tüm ayar sayfalarının
/// girdilerini içerir ve her girdi hedef sayfasını taşır. YENİ BİR AYAR
/// EKLERKEN bu listeye de bir girdi eklemeyi unutmayın; aksi halde arama
/// o ayarı bulamaz.
abstract final class SettingsRegistry {
  /// Not: girdiler başlık fonksiyonları taşıdığı için const liste
  /// yapılamaz; ilk erişimde bir kez kurulur.
  static final List<SettingsEntry> all = <SettingsEntry>[
    // --- Genel (satır-içi) ---
    SettingsEntry(
      key: SettingsKeys.languageCode,
      group: SettingsGroup.general,
      title: (l) => l.settingsLanguage,
    ),

    // --- Çalma (playback_settings_page) ---
    SettingsEntry(
      key: SettingsKeys.seekInterval,
      group: SettingsGroup.navigation,
      title: (l) => l.seekInterval,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.autoResume,
      group: SettingsGroup.navigation,
      title: (l) => l.autoResume,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.pauseHeadphone,
      group: SettingsGroup.navigation,
      title: (l) => l.pauseOnHeadphone,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.defaultShuffle,
      group: SettingsGroup.navigation,
      title: (l) => l.defaultShuffle,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.skipSilence,
      group: SettingsGroup.navigation,
      title: (l) => l.skipSilence,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.replayGain,
      group: SettingsGroup.navigation,
      title: (l) => l.replayGain,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.defaultRepeat,
      group: SettingsGroup.navigation,
      title: (l) => l.defaultRepeat,
      pageBuilder: () => const PlaybackSettingsPage(),
    ),

    // --- Kitaplık (library_settings_page) ---
    SettingsEntry(
      key: SettingsKeys.scanOnStartup,
      group: SettingsGroup.navigation,
      title: (l) => l.scanOnStartup,
      pageBuilder: () => const LibrarySettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.minDuration,
      group: SettingsGroup.navigation,
      title: (l) => l.minDuration,
      pageBuilder: () => const LibrarySettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.excludedFolders,
      group: SettingsGroup.navigation,
      title: (l) => l.excludedFolders,
      pageBuilder: () => const ExcludedFoldersPage(),
    ),

    // --- Ses/Efektler, widget, kapak, yedek, hakkında ---
    SettingsEntry(
      key: SettingsKeys.audioEffects,
      group: SettingsGroup.navigation,
      title: (l) => l.audioSettingsTitle,
      pageBuilder: () => const AudioSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.widgetTransparency,
      group: SettingsGroup.navigation,
      title: (l) => l.widgetSettings,
      pageBuilder: () => const WidgetSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.tagsArtwork,
      group: SettingsGroup.navigation,
      title: (l) => l.tagsArtworkSettings,
      pageBuilder: () => const TagsArtworkSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.backupRestore,
      group: SettingsGroup.navigation,
      title: (l) => l.backupTitle,
      pageBuilder: () => const BackupPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.about,
      group: SettingsGroup.navigation,
      title: (l) => l.settingsAbout,
      pageBuilder: () => const AboutPage(),
    ),

    // --- Görünüm ---
    SettingsEntry(
      key: SettingsKeys.themeMode,
      group: SettingsGroup.appearance,
      title: (l) => l.settingsThemeMode,
      pageBuilder: () => const ThemeSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeColorSource,
      group: SettingsGroup.appearance,
      title: (l) => l.themeGroupColor,
      pageBuilder: () => const ThemeGalleryPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeAmoled,
      group: SettingsGroup.appearance,
      title: (l) => l.themeAmoledOn,
      pageBuilder: () => const ThemeSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeHighContrast,
      group: SettingsGroup.appearance,
      title: (l) => l.themeHighContrast,
      pageBuilder: () => const ThemeSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeFont,
      group: SettingsGroup.appearance,
      title: (l) => l.themeFont,
      pageBuilder: () => const FontSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeTextScale,
      group: SettingsGroup.appearance,
      title: (l) => l.themeTextScale,
      pageBuilder: () => const FontSettingsPage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeAnimationLevel,
      group: SettingsGroup.appearance,
      title: (l) => l.themeAnimationLevel,
      pageBuilder: () => const PlayerStylePage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themePlayerStyle,
      group: SettingsGroup.appearance,
      title: (l) => l.themePlayerTitle,
      pageBuilder: () => const PlayerStylePage(),
    ),
    SettingsEntry(
      key: SettingsKeys.themeListStyle,
      group: SettingsGroup.appearance,
      title: (l) => l.themeListTitle,
      pageBuilder: () => const ListStylePage(),
    ),
  ];

  static SettingsEntry? find(String key) {
    for (final e in all) {
      if (e.key == key) return e;
    }
    return null;
  }

  static List<SettingsEntry> byGroup(SettingsGroup group) =>
      all.where((e) => e.group == group).toList(growable: false);

  /// Girdinin hedef sayfası (varsa). Arama sonuçlarında dokunma ile açılır.
  static Widget Function()? pageOf(String key) => find(key)?.pageBuilder;
}
