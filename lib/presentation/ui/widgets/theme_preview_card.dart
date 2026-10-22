import 'package:flutter/material.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// Tema değişikliklerini canlı gösteren örnek kart.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({super.key, required this.settings});

  final ThemeSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.themePreviewTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(l10n.themePreviewSongTitle),
              subtitle: Text(l10n.themePreviewSongArtist),
              trailing: Icon(
                Icons.favorite_border,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton(
                  onPressed: () {},
                  child: Text(l10n.commonOk),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(l10n.commonCancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}