import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';

class PlaylistPickerSheet extends StatelessWidget {
  const PlaylistPickerSheet({super.key, required this.song});
  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => PlaylistPickerSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<PlaylistController>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.addToPlaylist, style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(),
          Flexible(
            child: Obx(() {
              if (controller.playlists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noPlaylists),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.playlists.length,
                itemBuilder: (context, i) {
                  final p = controller.playlists[i];
                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(p.name),
                    onTap: () async {
                      await controller.addSongToPlaylist(p.id, song);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}