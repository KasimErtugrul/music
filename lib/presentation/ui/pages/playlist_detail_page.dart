import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class PlaylistDetailPage extends StatefulWidget {
  const PlaylistDetailPage({super.key});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final controller = Get.find<PlaylistController>();
  late int _playlistId;

  @override
  void initState() {
    super.initState();
    _playlistId = Get.arguments as int;
    controller.loadPlaylistDetail(_playlistId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentPlaylist.value?.name ?? '')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.currentSongs.isEmpty) {
          return EmptyState(icon: Icons.music_note, title: l10n.playlistEmpty);
        }
        return ReorderableListView.builder(
          itemCount: controller.currentSongs.length,
          onReorder: (o, n) => controller.reorderSongs(_playlistId, o, n),
          itemBuilder: (context, i) {
            final song = controller.currentSongs[i];
            return ListTile(
              key: ValueKey(song.id),
              leading: ArtworkImage(songId: song.id, size: 48),
              title: Text(song.title),
              subtitle: Text(song.artist ?? l10n.unknownArtist),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => controller.removeSong(_playlistId, song.id),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(l10n.deletePlaylistConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok == true) {
      await controller.deletePlaylist(_playlistId);
      Get.back();
    }
  }
}