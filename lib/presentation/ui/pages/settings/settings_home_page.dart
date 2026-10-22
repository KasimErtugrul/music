import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/settings_search_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';

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
        if (settings == null) {
          return const Center(child: Text('—'));
        }

        final general = search.filter(
          SettingsRegistry.byGroup(SettingsGroup.general),
          l10n,
        );
        final appearance = search.filter(
          SettingsRegistry.byGroup(SettingsGroup.appearance),
          l10n,
        );

        return ListView(
          children: <Widget>[
            if (general.isNotEmpty) ...<Widget>[
              SettingsSectionHeader(title: l10n.settingsGroupGeneral),
              ...general.map((e) => _entry(e, l10n, ctrl)),
            ],
            if (appearance.isNotEmpty) ...<Widget>[
              SettingsSectionHeader(title: l10n.settingsGroupAppearance),
              ...appearance.map((e) => _entry(e, l10n, ctrl)),
            ],
            const SettingsSectionHeader(title: '—'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              onTap: () => Get.to(() => const AboutPage()),
            ),
          ],
        );
      }),
    );
  }

  Widget _entry(SettingsEntry e, AppLocalizations l10n, SettingsController ctrl) {
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
      case 'theme_mode':
        return SettingsChoiceTile<String>(
          title: l10n.settingsThemeMode,
          value: ctrl.settings.value!.themeMode,
          options: const <String>['system', 'light', 'dark'],
          labelOf: (v) => switch (v) {
            'light' => l10n.settingsThemeLight,
            'dark' => l10n.settingsThemeDark,
            _ => l10n.settingsThemeSystem,
          },
          onChanged: ctrl.setThemeMode,
        );
      case 'dynamic_color':
        return SettingsSwitchTile(
          title: l10n.settingsDynamicColor,
          subtitle: l10n.settingsDynamicColorDescription,
          value: ctrl.settings.value!.dynamicColor,
          onChanged: ctrl.setDynamicColor,
        );
      case 'amoled_dark':
        return SettingsSwitchTile(
          title: l10n.settingsAmoledDark,
          subtitle: l10n.settingsAmoledDarkDescription,
          value: ctrl.settings.value!.amoledDark,
          onChanged: ctrl.setAmoledDark,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}