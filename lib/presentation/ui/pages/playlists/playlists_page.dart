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
      body: Column(
        children: [
          // Gün 15: Akıllı listeler ve istatistiklere geçici erişim butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.smartPlaylists),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.smartPlaylists),
                ),
                TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.stats),
                  icon: const Icon(Icons.bar_chart),
                  label: Text(l10n.statsTitle),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
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
                    // TODO düzeltildi: ARB çoğul anahtarına bağlandı.
                    subtitle: Text(l10n.songCount(p.songCount)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.playlistDetail, arguments: p.id),
                  );
                },
              );
            }),
          ),
        ],
      ),
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