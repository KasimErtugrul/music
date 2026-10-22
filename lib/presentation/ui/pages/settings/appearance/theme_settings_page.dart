import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/font_registry.dart';
import 'package:resonance/core/theme/theme_presets.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/widgets/theme_preview_card.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: Obx(() {
        final s = themeCtrl.settings.value;

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: <Widget>[
            // --- Mod ---
            SettingsSectionHeader(title: l10n.themeGroupMode),
            SettingsChoiceTile<ThemeMode>(
              title: l10n.settingsThemeMode,
              value: s.themeMode,
              options: ThemeMode.values,
              labelOf: (m) => switch (m) {
                ThemeMode.system => l10n.settingsThemeSystem,
                ThemeMode.light => l10n.settingsThemeLight,
                ThemeMode.dark => l10n.settingsThemeDark,
              },
              onChanged: themeCtrl.setMode,
            ),

            // --- Renk ---
            SettingsSectionHeader(title: l10n.themeGroupColor),
            SettingsChoiceTile<String>(
              title: l10n.themePresetSeed,
              value: 'default',
              options: ThemePresets.all.map((p) => p.id).toList(),
              labelOf: (id) => ThemePresets.find(id)?.name ?? id,
              onChanged: (id) {
                final preset = ThemePresets.find(id);
                if (preset != null) themeCtrl.setSeed(preset.seed);
              },
            ),
            SettingsSwitchTile(
              title: l10n.themeAmoledOn,
              value: s.amoled,
              onChanged: themeCtrl.setAmoled,
            ),
            SettingsSwitchTile(
              title: l10n.themeHighContrast,
              value: s.highContrast,
              onChanged: themeCtrl.setHighContrast,
            ),
            SettingsSwitchTile(
              title: l10n.themeSurfaceTint,
              value: s.surfaceTint,
              onChanged: themeCtrl.setSurfaceTint,
            ),

            // --- Şekil & yoğunluk ---
            SettingsSectionHeader(title: l10n.themeGroupShape),
            SettingsSwitchTile(
              title: l10n.themeRoundedCorners,
              value: s.roundedCorners,
              onChanged: themeCtrl.setRoundedCorners,
            ),
            SettingsChoiceTile<VisualDensity>(
              title: l10n.themeDensity,
              value: s.density,
              options: const <VisualDensity>[
                VisualDensity.compact,
                VisualDensity.standard,
                VisualDensity.comfortable,
              ],
              labelOf: (d) => switch (d) {
                VisualDensity.compact => l10n.themeDensityCompact,
                VisualDensity.standard => l10n.themeDensityStandard,
                _ => l10n.themeDensityComfortable,
              },
              onChanged: themeCtrl.setDensity,
            ),

            // --- Yazı tipi ---
            SettingsSectionHeader(title: l10n.themeGroupFont),
            SettingsChoiceTile<String>(
              title: l10n.themeFont,
              value: s.fontFamily,
              options: FontRegistry.fonts.map((f) => f.family).toList(),
              labelOf: (family) =>
                  FontRegistry.find(family)?.label ?? family,
              onChanged: themeCtrl.setFont,
            ),

            // --- Önizleme ---
            const SettingsSectionHeader(title: '—'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ThemePreviewCard(settings: s),
            ),
          ],
        );
      }),
    );
  }
}