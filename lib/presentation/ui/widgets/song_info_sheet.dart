import 'package:flutter/material.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

class SongInfoSheet extends StatelessWidget {
  const SongInfoSheet({super.key, required this.song});
  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SongInfoSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ArtworkImage(
                  songId: song.id,
                  size: 160,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  song.title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 32),
              _InfoRow(label: l10n.infoArtist, value: song.artist ?? l10n.unknownArtist),
              _InfoRow(label: l10n.infoAlbum, value: song.album ?? l10n.unknownAlbum),
              _InfoRow(label: l10n.infoGenre, value: song.genre ?? l10n.unknownGenre),
              _InfoRow(label: l10n.infoDuration, value: song.duration.clock),
              _InfoRow(label: l10n.infoSize, value: '${(song.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
              if (song.path.isNotEmpty)
                _InfoRow(label: l10n.infoPath, value: song.path),
              if (song.dateAdded != null)
                _InfoRow(
                  label: l10n.infoDateAdded,
                  value: song.dateAdded.toString().split('.').first,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}