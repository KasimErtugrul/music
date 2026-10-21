import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queueContext, // Şarkı tıklandığında kuyruğa alınacak liste
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
    final subtitle = <String>[
      song.artist ?? l10n.unknownArtist,
      song.album ?? l10n.unknownAlbum,
    ].join(' • ');

    return ListTile(
      leading: ArtworkImage(
        songId: song.id,
        size: 48,
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing ??
          Text(song.duration.clock, style: Theme.of(context).textTheme.bodySmall),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          Get.find<PlayerController>().playSong(song, queue: queueContext);
        }
      },
      onLongPress: () => SongOptionsSheet.show(context, song),
    );
  }
}