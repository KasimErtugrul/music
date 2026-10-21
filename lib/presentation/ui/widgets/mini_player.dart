import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';

class MiniPlayer extends GetView<PlayerController> {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.currentSong == null) return const SizedBox.shrink();

      return Material(
        elevation: 8,
        color: theme.colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.player),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 8),
                  ArtworkImage(
                    songId: controller.currentSong?.id,
                    size: 40,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentSong!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          controller.currentSong!.artist ?? 
                              AppLocalizations.of(context).unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const PlayerControls(compact: true),
                  const SizedBox(width: 8),
                ],
              ),
              // İnce ilerleme çubuğu
              const SeekBar(compact: true),
            ],
          ),
        ),
      );
    });
  }
}