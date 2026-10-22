import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/share_helper.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/playlist_picker_sheet.dart';
import 'package:resonance/presentation/ui/widgets/song_info_sheet.dart';

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
    final favCtrl = Get.find<FavoriteController>();
    final theme = Theme.of(context);

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
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l10n.addToPlaylist),
            onTap: () {
              Navigator.pop(context);
              PlaylistPickerSheet.show(context, song);
            },
          ),
          Obx(() {
            final isFav = favCtrl.isFavorite(song.id);
            return ListTile(
              leading: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? theme.colorScheme.error : null,
              ),
              title: Text(isFav ? l10n.removeFromFavorites : l10n.addToFavorites),
              onTap: () {
                favCtrl.toggle(song.id);
                Navigator.pop(context);
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l10n.share),
            onTap: () {
              Navigator.pop(context);
              ShareHelper.shareSong(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.songInfo),
            onTap: () {
              Navigator.pop(context);
              SongInfoSheet.show(context, song);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}