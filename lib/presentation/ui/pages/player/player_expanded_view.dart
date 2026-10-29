import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';

class PlayerExpandedView extends GetView<PlayerController> {
  const PlayerExpandedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: AspectRatio(
                aspectRatio: 1,
                child: ArtworkImage(
                  songId: controller.currentSong?.id,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentSong?.title ?? '',
                  style: theme.textTheme.displaySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Sanatçı adına dokununca sanatçının tüm şarkılarını
                // gösteren detay sayfası açılır.
                InkWell(
                  onTap: controller.openArtistDetail,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                    child: Text(
                      controller.currentSong?.artist ?? l10n.unknownArtist,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                // Aşama 2: format rozeti (codec · kHz · bit/kbps).
                Obx(() {
                  final label = controller.formatInfo.value?.label;
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                const SizedBox(height: 64),
                const SeekBar(),
                const SizedBox(height: 32),
                const PlayerControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}