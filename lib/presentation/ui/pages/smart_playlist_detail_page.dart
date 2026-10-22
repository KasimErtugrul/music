import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/smart_playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class SmartPlaylistDetailPage extends StatelessWidget {
  const SmartPlaylistDetailPage({
    super.key,
    required this.keyValue,
    required this.title,
  });

  final String keyValue;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Basit bir DI (Get.put) işlemi:
    final controller = Get.put(
      SmartPlaylistController(Get.find<StatsRepository>()),
      tag: keyValue,
    );
    controller.load(keyValue);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.songs.isEmpty) {
          return EmptyState(
            icon: Icons.music_note,
            title: l10n.libraryEmptySongsTitle,
          );
        }
        return ListView.builder(
          itemCount: controller.songs.length,
          itemBuilder: (context, i) => SongTile(
            song: controller.songs[i],
            queueContext: controller.songs,
          ),
        );
      }),
    );
  }
}