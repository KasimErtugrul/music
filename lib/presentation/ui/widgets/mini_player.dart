import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';

/// UI tasarım güncellemesi: mini oynatıcı artık alt gezinme çubuğunun
/// üzerinde yüzen YUVARLAK KÖŞELİ bir kart olarak çizilir (tasarımdaki
/// floating mini player). Kenar boşluğu kartın içinde verilir; hem compact
/// hem expanded yerleşimlerinde aynı görünümü alır.
///
/// Görev 3.3 (Aşama 3) aynen korunur: animasyon seviyesi gölgeyi ölçekler —
/// 'none' → düz çizim (gölge yok), 'reduced' → yumuşak gölge, aksi hâlde
/// tam elevasyon.
class MiniPlayer extends GetView<PlayerController> {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerSettings = Theme.of(context).extension<PlayerThemeExtension>() ?? PlayerThemeExtension.defaults;
    final isWide = playerSettings.miniPlayerStyle == 'wide';

    // Görev 3.3: animasyon seviyesi mini player gölgesini de ölçekler.
    final elevation = switch (playerSettings.animationLevel) {
      'none' => 0.0,
      'reduced' => 4.0,
      _ => 8.0,
    };

    return Obx(() {
      if (controller.currentSong == null) return const SizedBox.shrink();

      return Padding(
        // Tasarım: yüzen kart — yatayda kenar boşluğu, gezinme çubuğundan
        // önce hafif boşluk.
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Material(
          elevation: elevation,
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.player),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    ArtworkImage(
                      songId: controller.currentSong?.id,
                      size: 40,
                      borderRadius: BorderRadius.circular(8),
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
                    if (isWide) ...[
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: controller.previous,
                      ),
                      const PlayerControls(compact: true),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: controller.next,
                      ),
                    ] else ...[
                      const PlayerControls(compact: true),
                    ],
                    // Kuyruk: mini player'dan da sıradakilere tek dokunuşla
                    // erişim (kuyruk sayfasına ek giriş noktası).
                    IconButton(
                      icon: const Icon(Icons.queue_music_outlined),
                      tooltip: AppLocalizations.of(context).queue,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Get.toNamed(AppRoutes.queue),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                // İnce ilerleme çubuğu (alt kenara yapışık, kart köşeleri
                // clip'lenir)
                const SeekBar(compact: true),
              ],
            ),
          ),
        ),
      );
    });
  }
}
