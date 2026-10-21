import 'package:flutter/material.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

/// Tek bir şarkı satırı: kapak, başlık, sanatçı • albüm, süre.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.trailing,
  });

  final SongModel song;
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
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          Text(
            song.duration.clock,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      onTap: onTap,
    );
  }
}