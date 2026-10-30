import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/settings_search_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/font_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/list_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/player_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_gallery_page.dart';
import 'package:resonance/presentation/ui/pages/backup_page.dart';
import 'package:resonance/presentation/ui/pages/settings/audio_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/tags_artwork_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/notifications/notification_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/widget_settings_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';

/// UI tasarım güncellemesi: Ayarlar ana sayfası artık tasarım dilini izler —
/// yuvarlak arama çubuğu gövdede, ikonlu+kategorik grup kartları ve altta
/// gerçek veriden beslenen bir durum kartı.
///
/// Arama davranışı Görev 4.2'den aynen korunur: sorgu boş değilken eşleşme
/// tüm [SettingsRegistry] girdileri üzerinde yapılır (iki dilli) ve sonuç,
/// hedef sayfaya giden satırlar olarak basılır (pageBuilder + Get.to).
class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key});

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctrl = Get.find<SettingsController>();
    final search = Get.put(SettingsSearchController());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: Column(
        children: [
          // --- M3 arama çubuğu (tasarım: yuvarlak, dolgulu) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => search.query.value = v,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.settingsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: l10n.commonClear,
                          onPressed: () {
                            _searchController.clear();
                            search.query.value = '';
                          },
                        ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHigh,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final settings = ctrl.settings.value;
              if (settings == null) return const Center(child: Text('—'));

              // Görev 4.2: arama boş değilse registry üzerinden iki dilli
              // eşleme; sonuç satırı hedef sayfayı builder ile açar.
              if (search.query.value.trim().isNotEmpty) {
                final results = search.filter(SettingsRegistry.all, l10n);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: <Widget>[
                    for (final e in results)
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(e.title(l10n)),
                        trailing: e.pageBuilder != null
                            ? const Icon(Icons.chevron_right)
                            : null,
                        onTap: e.pageBuilder == null
                            ? null
                            : () => Get.to(e.pageBuilder!),
                      ),
                  ],
                );
              }

              final general = search.filter(
                SettingsRegistry.byGroup(SettingsGroup.general),
                l10n,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  if (general.isNotEmpty) ...<Widget>[
                    SettingsSectionHeader(title: l10n.settingsGroupGeneral),
                    _NavCard(children: [
                      ...general.map((e) => _entry(e, l10n, ctrl)),
                    ]),
                  ],

                  // --- Genel & motor ---
                  _NavCard(children: [
                    _NavRow(
                      icon: Icons.play_circle_outline,
                      title: l10n.settingsPlayback,
                      desc: l10n.settingsDescPlayback,
                      onTap: () => Get.to(() => const PlaybackSettingsPage()),
                    ),
                    _NavRow(
                      icon: Icons.equalizer,
                      title: l10n.audioSettingsTitle,
                      desc: l10n.settingsDescAudio,
                      onTap: () => Get.to(() => const AudioSettingsPage()),
                    ),
                  ]),

                  // --- Kütüphane ve içerik ---
                  SettingsSectionHeader(title: l10n.settingsGroupContent),
                  _NavCard(children: [
                    _NavRow(
                      icon: Icons.folder_special,
                      title: l10n.settingsLibrary,
                      desc: l10n.settingsDescLibrary,
                      onTap: () => Get.to(() => const LibrarySettingsPage()),
                    ),
                    _NavRow(
                      icon: Icons.image_outlined,
                      title: l10n.tagsArtworkSettings,
                      desc: l10n.settingsDescTags,
                      onTap: () =>
                          Get.to(() => const TagsArtworkSettingsPage()),
                    ),
                    _NavRow(
                      icon: Icons.widgets_outlined,
                      title: l10n.widgetSettings,
                      desc: l10n.settingsDescWidget,
                      onTap: () => Get.to(() => const WidgetSettingsPage()),
                    ),
                    _NavRow(
                      icon: Icons.notifications_outlined,
                      title: l10n.settingsRowNotifications,
                      desc: l10n.settingsDescNotifications,
                      onTap: () =>
                          Get.to(() => const NotificationSettingsPage()),
                    ),
                  ]),

                  // --- Görünüm ---
                  SettingsSectionHeader(title: l10n.settingsGroupAppearance),
                  _NavCard(children: [
                    _NavRow(
                      icon: Icons.palette_outlined,
                      title: l10n.settingsRowAppearance,
                      desc: l10n.settingsDescTheme,
                      onTap: () => Get.to(() => const ThemeGalleryPage()),
                    ),
                    _NavRow(
                      icon: Icons.text_fields,
                      title: l10n.themeFont,
                      desc: l10n.settingsDescFont,
                      onTap: () => Get.to(() => const FontSettingsPage()),
                    ),
                    _NavRow(
                      icon: Icons.music_note,
                      title: l10n.themePlayerTitle,
                      desc: l10n.settingsDescPlayerStyle,
                      onTap: () => Get.to(() => const PlayerStylePage()),
                    ),
                    _NavRow(
                      icon: Icons.list_alt,
                      title: l10n.themeListTitle,
                      desc: l10n.settingsDescListStyle,
                      onTap: () => Get.to(() => const ListStylePage()),
                    ),
                  ]),

                  // --- Sistem ---
                  SettingsSectionHeader(title: l10n.settingsGroupSystem),
                  _NavCard(children: [
                    _NavRow(
                      icon: Icons.backup,
                      title: l10n.backupTitle,
                      desc: l10n.settingsDescBackup,
                      onTap: () => Get.to(() => const BackupPage()),
                    ),
                    _NavRow(
                      icon: Icons.info_outline,
                      title: l10n.settingsAbout,
                      desc: l10n.settingsDescAbout,
                      onTap: () => Get.to(() => const AboutPage()),
                    ),
                  ]),

                  // --- Gün 6: Tüm ayarları sıfırla ---
                  // Yıkıcı eylem en sonda, kendi kartında. Taban l10n
                  // dizgeleri (resetAll / resetConfirm) Gün 6 ile ilk kez
                  // gerçek bir ekrana bağlandı.
                  _NavCard(children: [
                    _NavRow(
                      icon: Icons.restart_alt,
                      title: l10n.resetAll,
                      desc: l10n.resetAllDesc,
                      onTap: () => _confirmReset(context),
                    ),
                  ]),

                  // --- Alt durum kartı (gerçek veri) ---
                  const SizedBox(height: 16),
                  const _EngineStatusCard(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _entry(
    SettingsEntry e,
    AppLocalizations l10n,
    SettingsController ctrl,
  ) {
    switch (e.key) {
      case 'language_code':
        return SettingsChoiceTile<String>(
          title: l10n.settingsLanguage,
          value: ctrl.settings.value!.languageCode,
          options: const <String>['system', 'tr', 'en'],
          labelOf: (v) => switch (v) {
            'tr' => 'Türkçe',
            'en' => 'English',
            _ => l10n.settingsLanguageSystem,
          },
          onChanged: ctrl.setLanguage,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Gün 6: sıfırlama onayı. Onaylanırsa diskteki tüm yedeklenen ayar
  /// anahtarları kaldırılır ve canlı controller'lar yeniden yüklenir
  /// (PreferencesController.resetAll); sonuç SnackBar ile bildirilir.
  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetAll),
        content: Text(l10n.resetConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.resetAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await Get.find<PreferencesController>().resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.resetDone)),
    );
  }
}

/// Kategorik grup kartı: tek yüzeyde toplanmış satırlar (tasarım:
/// surface-container-low + rounded-xl).
class _NavCard extends StatelessWidget {
  const _NavCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Kategori satırı: ikon rozeti + başlık + açıklama + chevron.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Alt durum kartı. Tasarımdaki "ses motoru" rozetinin dürüst karşılığı:
/// uydurma bit-perfect bilgisi yerine kitaplık parça sayısı ve ekolayzır
/// durumu gösterilir (ikisi de gerçek, canlı veridir).
class _EngineStatusCard extends StatelessWidget {
  const _EngineStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasLibrary = Get.isRegistered<LibraryController>();
    final hasEq = Get.isRegistered<EqualizerController>();
    if (!hasLibrary && !hasEq) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusText(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          if (hasEq)
            Obx(() {
              final eq = Get.find<EqualizerController>();
              final on = eq.isEnabled.value;
              return Text(
                on
                    ? AppLocalizations.of(context).settingsStatusEqOn
                    : AppLocalizations.of(context).settingsStatusEqOff,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: on ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (Get.isRegistered<LibraryController>()) {
      final lib = Get.find<LibraryController>();
      final n = lib.songs.length;
      return '${l10n.settingsLibrary}: $n ${l10n.settingsStatusSongs}';
    }
    return l10n.settingsGroupGeneral;
  }
}