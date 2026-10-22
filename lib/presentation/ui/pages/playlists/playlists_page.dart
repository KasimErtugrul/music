import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class PlaylistsPage extends GetView<PlaylistController> {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.playlistsTitle)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.playlists.isEmpty) {
          return EmptyState(
            icon: Icons.queue_music,
            title: l10n.noPlaylists,
            message: l10n.noPlaylistsMessage,
          );
        }
        return ListView.builder(
          itemCount: controller.playlists.length,
          itemBuilder: (context, i) {
            final p = controller.playlists[i];
            return ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.songCount} şarkı'), // TODO: ARB ekle
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(AppRoutes.playlistDetail, arguments: p.id),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createPlaylist),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: l10n.playlistNameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await controller.createPlaylist(name);
    }
  }
}