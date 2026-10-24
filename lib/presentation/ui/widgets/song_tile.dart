import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queueContext,
    this.onTap,
    this.trailing,
  });

  final SongModel song;
  final List<SongModel>? queueContext;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = Get.find<PlayerController>();
    final favCtrl = Get.find<FavoriteController>();
    final theme = Theme.of(context);

    return Obx(() {
      final isCurrent = player.currentItem.value?.id == song.uri;
      final isFav = favCtrl.isFavorite(song.id);

      final subtitle = <String>[
        song.artist ?? l10n.unknownArtist,
        song.album ?? l10n.unknownAlbum,
      ].join(' • ');

      return ListTile(
        selected: isCurrent,
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        leading: ArtworkImage(
          songId: song.id,
          size: 48,
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? theme.colorScheme.primary : null,
            fontWeight: isCurrent ? FontWeight.bold : null,
          ),
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing ?? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? theme.colorScheme.error : null,
                size: 20,
              ),
              onPressed: () => favCtrl.toggle(song)
            ),
            const SizedBox(width: 8),
            Text(song.duration.clock, style: theme.textTheme.bodySmall),
          ],
        ),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            player.playSong(song, queue: queueContext);
          }
        },
        onLongPress: () => SongOptionsSheet.show(context, song),
      );
    });
  }
}