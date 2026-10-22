import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.appName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.settingsVersionLabel('1.0.0')),
          const Divider(height: 32),
          Text(l10n.settingsAboutDescription),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.settingsLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}