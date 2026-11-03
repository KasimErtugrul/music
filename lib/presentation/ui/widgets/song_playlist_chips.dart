import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

/// Şarkının üyesi olduğu çalma listelerini rozet çipleri olarak çizer.
///
/// Bulgu 1/3/7'nin ortak bileşeni: SongTile rozeti (kütüphane, arama,
/// favoriler...), kuyruk kartları ve oynatıcı ekranı (kompakt + geniş)
/// aynı bileşeni kullanır. PlaylistController kayıtlı değilse (binding'siz
/// testler) sessizce daralır; harita reaktif olduğu için üyelik
/// değişince çipler kendiliğinden güncellenir.
class SongPlaylistChips extends StatelessWidget {
  const SongPlaylistChips({super.key, required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PlaylistController>()) {
      return const SizedBox.shrink();
    }
    final playlistCtrl = Get.find<PlaylistController>();
    return Obx(() {
      final names = playlistCtrl.listNamesOf(songId);
      if (names.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 3, left: 2),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [for (final n in names) PlaylistBadge(names: [n])],
        ),
      );
    });
  }
}
