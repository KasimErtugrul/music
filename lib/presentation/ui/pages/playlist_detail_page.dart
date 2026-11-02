
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

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
        // Gün 19: sayfa artık salt bir düzenleyici değil — albüm/sanatçı
        // detayındaki eylem kümesiyle LİSTE olarak çalınıyor.
        return Column(
          children: [
            _ActionCluster(
              playlistId: _playlistId,
              controller: controller,
            ),
            const Divider(height: 1),
            Expanded(
              child: ReorderableListView.builder(
                // Varsayılan uzun-bas tutamacı, SongTile'ın uzun-bas
                // seçenekler menüsüyle aynı hareketi paylaşır ve çekişme
                // belirsizdir (parmak kıpırdarsa sürükleme, durursa menü —
                // güvensiz). Ayrı tutamacı görünür kılarız: sürükleme
                // yalnız tutamaçtan, uzun bas her satırda menü açar.
                buildDefaultDragHandles: false,
                itemCount: controller.currentSongs.length,
                // onReorderItem: newIndex «çıkarma sonrası» konumdur
                // (kütüphane önceden düzeltir); controller bu sözleşmede.
                onReorderItem: (o, n) =>
                    controller.reorderSongs(_playlistId, o, n),
                itemBuilder: (context, i) {
                  final song = controller.currentSongs[i];
                  return Row(
                    key: ValueKey(song.id),
                    children: [
                      Expanded(
                        // queueContext: playlistin TAMAMI — dokunulan
                        // parçadan itibaren kuyruk playlist sırasıyla
                        // kurulur (akıllı listelerdeki sözleşme).
                        child: SongTile(
                          song: song,
                          queueContext: controller.currentSongs.toList(),
                          playlistId: _playlistId,
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 25,
                          ),
                          child: Icon(Icons.drag_handle, size: 22),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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

/// Gün 19: albüm/sanatçı detay sayfalarındaki eylem kümesinin playlist
/// sürümü. Görsel ve davranışsal sözleşme aynı: «Sırayla Çal» kuyruğu
/// playlist sırasıyla kurar; «Tümünü Karıştır» karıştırmayı açar ve
/// rastgele bir parçayla başlar. Çalma mantığı PlaylistController'da
/// (playPlaylist) — listeler sayfasındaki hızlı çal düğmesi de aynı
/// kaynağı kullanır.
class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.playlistId,
    required this.controller,
  });
  final int playlistId;
  final PlaylistController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => controller.playPlaylist(playlistId),
              icon: const Icon(Icons.play_arrow, size: 22),
              label: Text(l10n.playInOrder),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  controller.playPlaylist(playlistId, shuffled: true),
              icon: const Icon(Icons.shuffle, size: 20),
              label: Text(l10n.shuffleAll),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
