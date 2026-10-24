import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/tag_editor_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/tag_viewer_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

class TagViewerPage extends StatelessWidget {
  const TagViewerPage({super.key, required this.song});
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.put(
      TagViewerController(Get.find<TagEditorRepository>()),
    );
    ctrl.load(song, l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagViewer)),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.errorMsg.value != null) {
          return Center(child: Text(ctrl.errorMsg.value!));
        }

        final tag = ctrl.tag.value;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kapak: MediaStore üzerinden
            Center(
              child: ArtworkImage(
                songId: song.id,
                size: 150,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            _infoRow(context, l10n.tagTitle, tag?.title ?? song.title),
            _infoRow(context, l10n.tagArtist, tag?.artist ?? song.artist ?? ''),
            _infoRow(context, l10n.tagAlbum, tag?.album ?? song.album ?? ''),
            _infoRow(context, l10n.tagGenre, tag?.genre ?? song.genre ?? ''),
            _infoRow(context, l10n.tagYear, tag?.year ?? ''),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tagReadOnlyNote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}