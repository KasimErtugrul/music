import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/settings_search_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/pages/settings/audio_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/tags_artwork_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/widget_settings_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<SettingsController>();
    final search = Get.put(SettingsSearchController());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSettings),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => search.query.value = v,
              decoration: InputDecoration(
                hintText: l10n.settingsSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final settings = ctrl.settings.value;
        if (settings == null) return const Center(child: Text('—'));

        final general = search.filter(
          SettingsRegistry.byGroup(SettingsGroup.general),
          l10n,
        );

        return ListView(
          children: <Widget>[
            if (general.isNotEmpty) ...<Widget>[
              SettingsSectionHeader(title: l10n.settingsGroupGeneral),
              ...general.map((e) => _entry(e, l10n, ctrl)),
            ],

            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(l10n.settingsPlayback),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const PlaybackSettingsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(l10n.settingsLibrary),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const LibrarySettingsPage()),
            ),

             ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: Text(l10n.audioSettingsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const AudioSettingsPage()),
            ),

                        ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.tagsArtworkSettings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const TagsArtworkSettingsPage()),
            ),

            // ListView children'ına ekle:
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l10n.widgetSettings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const WidgetSettingsPage()),
            ),

            // ListView children'ına ekle:
            ListTile(
              leading: const Icon(Icons.backup),
              title: Text(l10n.backupTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.backup),
            ),

            // Gün 18: Görünüm ayarları — tam tema sistemi
            SettingsSectionHeader(title: l10n.settingsGroupAppearance),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.themeGroupColor),
              subtitle: Text(l10n.themeGroupMode),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.themeGallery), // ← galeriye
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(l10n.themeFont),
              subtitle: Text(l10n.themeTextScale),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.fontSettings),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(l10n.themePlayerTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.playerStyle),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(l10n.themeListTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.listStyle),
            ),

            // Hakkında
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const AboutPage()),
            ),
          ],
        );
      }),
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
}
