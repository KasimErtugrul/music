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
              subtitle: l10n.themeModeDesc,
              value: s.themeMode,
              options: ThemeMode.values,
              labelOf: (m) => switch (m) {
                ThemeMode.system => l10n.settingsThemeSystem,
                ThemeMode.light => l10n.settingsThemeLight,
                ThemeMode.dark => l10n.settingsThemeDark,
              },
              onChanged: themeCtrl.setMode,
            ),
            if (s.themeMode == ThemeMode.system) ...[
              // Gün 3 (Karar): zamanlanmış koyu mod varsayılan kapalıdır;
              // anahtar açılmadan saat aralığı uygulanmaz.
              SettingsSwitchTile(
                title: l10n.themeScheduledDark,
                subtitle: l10n.themeScheduledDarkDesc,
                value: s.scheduledDarkEnabled,
                onChanged: themeCtrl.setScheduledDarkEnabled,
              ),
              if (s.scheduledDarkEnabled)
                ListTile(
                  title: Text(
                    '${s.scheduledDarkStartHour.toString().padLeft(2, '0')}:${s.scheduledDarkStartMinute.toString().padLeft(2, '0')}'
                    ' - '
                    '${s.scheduledDarkEndHour.toString().padLeft(2, '0')}:${s.scheduledDarkEndMinute.toString().padLeft(2, '0')}'
                  ),
                  onTap: () async {
                    final start = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: s.scheduledDarkStartHour, minute: s.scheduledDarkStartMinute),
                    );
                    if (start == null) return;
                    if (!context.mounted) return;
                    final end = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: s.scheduledDarkEndHour, minute: s.scheduledDarkEndMinute),
                    );
                    if (end == null) return;

                    themeCtrl.setScheduledDark(
                      start.hour, start.minute,
                      end.hour, end.minute
                    );
                  },
                ),
            ],

            // --- Renk ---
            SettingsSectionHeader(title: l10n.themeGroupColor),
            // Gün 12: başlık ve seçenek etiketleri l10n'a taşındı (Galeri
            // sayfasıyla aynı anahtarlar: themeColorSource / themeSource*).
            SettingsChoiceTile<String>(
              title: l10n.themeColorSource,
              subtitle: l10n.themeColorSourceDesc,
              value: s.themeSource,
              options: const ['seed', 'system', 'artwork'],
              labelOf: (v) => switch (v) {
                'system' => l10n.themeSourceSystem,
                'artwork' => l10n.themeSourceArtwork,
                _ => l10n.themeSourceSeed,
              },
              onChanged: themeCtrl.setThemeSource,
            ),
            if (s.themeSource == 'seed')
              SettingsChoiceTile<String>(
                title: l10n.themePresetSeed,
                subtitle: l10n.themePresetSeedDesc,
                // Gün 3: palet seçim durumu artık gerçek tohumdan türetilir;
                // eskiden değer sabit 'default' idi ve seçili palet hiç
                // gösterilmiyordu. Tohum bir palete denk gelmezse (özel
                // renk) 'default' yedek değeri kullanılır — davranış
                // korunur (Gün 12: bu bileşen artık alt sayfa açar,
                // DropdownButton kaldırıldı).
                value: ThemePresets.all
                        .where((p) => p.seed == s.seedColor)
                        .map((p) => p.id)
                        .firstOrNull ??
                    'default',
                options: ThemePresets.all.map((p) => p.id).toList(),
                labelOf: (id) => ThemePresets.find(id)?.name ?? id,
                onChanged: (id) {
                  final preset = ThemePresets.find(id);
                  if (preset != null) themeCtrl.setSeed(preset.seed);
                },
              ),
            SettingsSwitchTile(
              title: l10n.themeAmoledOn,
              subtitle: l10n.themeAmoledOnDesc,
              value: s.amoled,
              onChanged: themeCtrl.setAmoled,
            ),
            SettingsSwitchTile(
              title: l10n.themeHighContrast,
              subtitle: l10n.themeHighContrastDesc,
              value: s.highContrast,
              onChanged: themeCtrl.setHighContrast,
            ),
            SettingsSwitchTile(
              title: l10n.themeSurfaceTint,
              subtitle: l10n.themeSurfaceTintDesc,
              value: s.surfaceTint,
              onChanged: themeCtrl.setSurfaceTint,
            ),

            // --- Şekil & yoğunluk ---
            SettingsSectionHeader(title: l10n.themeGroupShape),
            SettingsSwitchTile(
              title: l10n.themeRoundedCorners,
              subtitle: l10n.themeRoundedCornersDesc,
              value: s.roundedCorners,
              onChanged: themeCtrl.setRoundedCorners,
            ),
            SettingsChoiceTile<VisualDensity>(
              title: l10n.themeDensity,
              subtitle: l10n.themeDensityDesc,
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
              subtitle: l10n.themeFontDesc,
              value: s.fontFamily,
              options: FontRegistry.fonts.map((f) => f.family).toList(),
              labelOf: (family) =>
                  FontRegistry.find(family)?.label ?? family,
              onChanged: themeCtrl.setFont,
            ),

            // --- Önizleme ---
            // Gün 12: '—' başlığı yerine gerçek bölüm adı (mevcut l10n
            // anahtarı: themePreviewTitle).
            SettingsSectionHeader(title: l10n.themePreviewTitle),
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