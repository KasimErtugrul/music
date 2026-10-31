import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/pages/equalizer_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_tile.dart';

class AudioSettingsPage extends StatelessWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioSettingsTitle)),
      body: ListView(
        // Gün 12: ham ListTile yerine ortak SettingsTile + grup kartı.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingsGroupCard(children: [
            SettingsTile(
              leading: const Icon(Icons.equalizer),
              title: l10n.equalizerTitle,
              subtitle: l10n.settingsDescAudio,
              onTap: () => Get.to(() => const EqualizerPage()),
            ),
          ]),
        ],
      ),
    );
  }
}
