import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

/// Görev 3.4: Liste stili ayarı (listViewMode) sanatçı sekmesine de
/// uygulanır. Izgara modunda sanatçı kapakları YUVARLAK kart olarak
/// gösterilir (albümdeki kare orandan farklı içerik kararı).
class ArtistsPage extends GetView<LibraryController> {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final player = Get.find<PlayerController>();
    final listMode = Get.find<ThemeController>().settings.value.listViewMode;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError.value) {
        return EmptyState(
          icon: Icons.error_outline,
          title: l10n.libraryLoadErrorTitle,
          message: l10n.libraryLoadErrorMessage,
          action: FilledButton(
            onPressed: controller.loadAll,
            child: Text(l10n.commonRetry),
          ),
        );
      }
      if (controller.artists.isEmpty) {
        return EmptyState(
          icon: Icons.person_outline,
          title: l10n.libraryEmptyArtistsTitle,
          message: l10n.libraryEmptyArtistsMessage,
        );
      }

      final currentArtistId = player.currentSong?.artistId;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              Responsive.fromWidth(constraints.maxWidth) != WindowSize.compact;
          final isGrid = listMode == 'grid' || (isWide && listMode != 'compact');
          final dense = listMode == 'compact';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.songCount(controller.artists.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.sort,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isGrid
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          // Yuvarlak kapak + isim + istatistik bloğu.
                          childAspectRatio: 0.82,
                        ),
                        itemCount: controller.artists.length,
                        itemBuilder: (context, i) {
                          final artist = controller.artists[i];
                          final isCurrent = currentArtistId != null &&
                              currentArtistId == artist.id;
                          return _ArtistCard(
                            artist: artist,
                            isCurrent: isCurrent,
                            onTap: () => Get.toNamed<dynamic>(
                              AppRoutes.artistDetail,
                              arguments: artist,
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: dense ? 4 : 8,
                        ),
                        itemExtent: dense ? 64.0 : 76.0,
                        itemCount: controller.artists.length,
                        itemBuilder: (context, i) {
                          final artist = controller.artists[i];
                          final isCurrent = currentArtistId != null &&
                              currentArtistId == artist.id;
                          return _ArtistTile(
                            artist: artist,
                            isCurrent: isCurrent,
                            dense: dense,
                            onTap: () => Get.toNamed<dynamic>(
                              AppRoutes.artistDetail,
                              arguments: artist,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    });
  }
}

/// Görev 3.4: yuvarlak kapaklı ızgara kartı.
class _ArtistCard extends StatelessWidget {
  const _ArtistCard({
    required this.artist,
    required this.onTap,
    this.isCurrent = false,
  });

  final ArtistModel artist;
  final VoidCallback onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                child: ArtworkImage(
                  songId: artist.artworkSongId,
                  fallbackIcon: Icons.person_outline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist.name ?? l10n.unknownArtist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isCurrent ? theme.colorScheme.primary : null,
            ),
          ),
          Text(
            l10n.songCount(artist.songCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({
    required this.artist,
    required this.onTap,
    this.isCurrent = false,
    this.dense = false,
  });

  final ArtistModel artist;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 4 : 8),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: ArtworkImage(
                songId: artist.artworkSongId,
                size: dense ? 44 : 56,
                borderRadius: BorderRadius.circular(dense ? 22 : 28),
                fallbackIcon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artist.name ?? l10n.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.albumCount(artist.albumCount)} • ${l10n.songCount(artist.songCount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(
                Icons.equalizer,
                size: 20,
                color: theme.colorScheme.primary,
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
