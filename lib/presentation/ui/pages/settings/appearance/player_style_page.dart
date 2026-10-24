import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';

class PlayerStylePage extends StatelessWidget {
  const PlayerStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themePlayerTitle)),
      body: Obx(() {
        final p = themeCtrl.settings.value.player;

        return ListView(
          children: <Widget>[
            const SettingsSectionHeader(title: '—'),
            SettingsChoiceTile<String>(
              title: 'Background',
              value: p.backgroundStyle,
              options: const <String>['solid', 'gradient', 'blur'],
              labelOf: (v) => switch (v) {
                'gradient' => l10n.playerBackgroundGradient,
                'blur' => l10n.playerBackgroundBlur,
                _ => l10n.playerBackgroundSolid,
              },
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(backgroundStyle: v)),
            ),
            SettingsChoiceTile<String>(
              title: 'Artwork shape',
              value: p.artworkShape,
              options: const <String>['square', 'rounded', 'circle'],
              labelOf: (v) => switch (v) {
                'square' => l10n.playerArtworkSquare,
                'circle' => l10n.playerArtworkCircle,
                _ => l10n.playerArtworkRounded,
              },
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(artworkShape: v)),
            ),
            SettingsChoiceTile<String>(
              title: l10n.seekBarStyle,
              value: p.seekBarStyle == 'waveform' ? 'classic' : p.seekBarStyle,
              options: const <String>['classic', 'thin'],
              labelOf: (v) =>
                  v == 'thin' ? l10n.seekBarThin : l10n.seekBarClassic,
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(seekBarStyle: v)),
            ),
            SettingsChoiceTile<String>(
              title: 'Mini player',
              value: p.miniPlayerStyle,
              options: const <String>['compact', 'wide'],
              labelOf: (v) => v == 'wide' ? 'Wide' : 'Compact',
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(miniPlayerStyle: v)),
            ),
          ],
        );
      }),
    );
  }
}