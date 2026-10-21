import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class QueuePage extends GetView<PlayerController> {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.queueTitle),
        actions: [
          Obx(() {
            if (controller.songQueue.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: l10n.clearQueue,
              onPressed: () => _confirmClear(context),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.songQueue.isEmpty) {
          return EmptyState(
            icon: Icons.queue_music,
            title: l10n.queueEmpty,
          );
        }

        return ReorderableListView.builder(
          itemCount: controller.songQueue.length,
          onReorder: controller.reorderQueue,
          itemBuilder: (context, index) {
            final song = controller.songQueue[index];
            final isCurrent = controller.currentItem.value?.id == song.uri;

            return ListTile(
              key: ValueKey(song.id),
              selected: isCurrent,
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
                  color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: isCurrent ? FontWeight.bold : null,
                ),
              ),
              subtitle: Text(
                song.artist ?? l10n.unknownArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(song.duration.clock, style: Theme.of(context).textTheme.bodySmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.removeFromQueue(index),
                  ),
                ],
              ),
              onTap: () => controller.playSong(song, queue: controller.songQueue.toList()),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearQueue),
        content: Text(l10n.clearQueueConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok == true) {
      await controller.clearQueue();
    }
  }
}