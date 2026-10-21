import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class SongOptionsSheet extends StatelessWidget {
  const SongOptionsSheet({super.key, required this.song});
  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => SongOptionsSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = Get.find<PlayerController>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artist ?? l10n.unknownArtist),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l10n.playNext),
            onTap: () {
              player.playNext(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(l10n.addToQueue),
            onTap: () {
              player.addToQueue(song);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}