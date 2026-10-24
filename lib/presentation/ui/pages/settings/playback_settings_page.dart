import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';

class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<PreferencesController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPlayback)),
      body: Obx(() {
        final p = ctrl.playback.value;
        return ListView(
          children: [
            SettingsChoiceTile<int>(
              title: l10n.seekInterval,
              value: p.seekIntervalSeconds,
              options: const [5, 10, 15, 30],
              labelOf: (v) => l10n.seekIntervalValue(v),
              onChanged: ctrl.setSeekInterval,
            ),
            SettingsSwitchTile(
              title: l10n.autoResume,
              value: p.autoResume,
              onChanged: ctrl.setAutoResume,
            ),
            SettingsSwitchTile(
              title: l10n.pauseOnHeadphone,
              value: p.pauseOnHeadphone,
              onChanged: ctrl.setPauseOnHeadphone,
            ),
            SettingsSwitchTile(
              title: l10n.defaultShuffle,
              value: p.defaultShuffle,
              onChanged: ctrl.setDefaultShuffle,
            ),
            SettingsSwitchTile(
              title: l10n.gaplessPlayback,
              value: p.gapless,
              onChanged: ctrl.setGapless,
            ),
            SettingsSwitchTile(
              title: l10n.skipSilence,
              value: p.skipSilence,
              onChanged: ctrl.setSkipSilence,
            ),
            SettingsChoiceTile<int>(
              title: l10n.defaultRepeat,
              value: p.defaultRepeat,
              options: const [0, 1, 2],
              labelOf: (v) => switch (v) {
                1 => l10n.repeatAll,
                2 => l10n.repeatOne,
                _ => l10n.repeatNone,
              },
              onChanged: ctrl.setDefaultRepeat,
            ),
          ],
        );
      }),
    );
  }
}