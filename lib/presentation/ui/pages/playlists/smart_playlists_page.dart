import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/constants/smart_playlist_keys.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/pages/smart_playlist_detail_page.dart';

class SmartPlaylistsPage extends StatelessWidget {
  const SmartPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.smartPlaylists)),
      body: ListView(
        children: [
          _SmartPlaylistTile(
            icon: Icons.new_releases,
            title: l10n.recentlyAdded,
            keyValue: SmartPlaylistKeys.recentlyAdded,
          ),
          _SmartPlaylistTile(
            icon: Icons.trending_up,
            title: l10n.mostPlayed,
            keyValue: SmartPlaylistKeys.mostPlayed,
          ),
          _SmartPlaylistTile(
            icon: Icons.music_off,
            title: l10n.neverPlayed,
            keyValue: SmartPlaylistKeys.neverPlayed,
          ),
        ],
      ),
    );
  }
}

class _SmartPlaylistTile extends StatelessWidget {
  const _SmartPlaylistTile({
    required this.icon,
    required this.title,
    required this.keyValue,
  });

  final IconData icon;
  final String title;
  final String keyValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.to(
        () => SmartPlaylistDetailPage(keyValue: keyValue, title: title),
      ),
    );
  }
}