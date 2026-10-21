import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';

class PlayerPage extends GetView<PlayerController> {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playerTitle),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Kapak
            Obx(() {
              final song = controller.currentSong;
              if (song == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ArtworkImage(
                    songId: song.id,
                    borderRadius: BorderRadius.circular(24),
                    fallbackIcon: Icons.music_note,
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            // Başlık ve Sanatçı
            Obx(() {
              final song = controller.currentSong;
              if (song == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artist ?? l10n.unknownArtist,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
            const Spacer(),
            // Seek Bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SeekBar(),
            ),
            // Kontroller
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: PlayerControls(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}