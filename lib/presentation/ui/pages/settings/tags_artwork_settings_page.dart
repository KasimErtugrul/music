import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

class TagsArtworkSettingsPage extends StatelessWidget {
  const TagsArtworkSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsArtworkSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: Text(l10n.clearArtworkCache),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.artworkCacheCleared)),
              );
            },
          ),
        ],
      ),
    );
  }
}