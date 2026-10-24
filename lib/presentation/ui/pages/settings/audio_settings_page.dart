import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/pages/equalizer_page.dart';

class AudioSettingsPage extends StatelessWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioSettingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.equalizer),
            title: Text(l10n.equalizerTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const EqualizerPage()),
          ),
        ],
      ),
    );
  }
}