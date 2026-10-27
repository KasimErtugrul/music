import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

/// Görev 3.4: Liste stili ayarı (listViewMode) artık albüm sekmesine de
/// uygulanır. songs_page'deki karar mantığı aynen taşındı: 'grid' açıkça
/// seçildiyse veya pencere geniş (tablet) ve 'compact' değilse ızgara,
/// aksi hâlde liste. Kompakt seçeneği liste satır yoğunluğunu azaltır.
class AlbumsPage extends GetView<LibraryController> {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
      if (controller.albums.isEmpty) {
        return EmptyState(
          icon: Icons.album_outlined,
          title: l10n.libraryEmptyAlbumsTitle,
          message: l10n.libraryEmptyAlbumsMessage,
        );
      }

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
                      l10n.albumCount(controller.albums.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        // Görev 3.4: rozet artık gerçek düzeni yansıtır.
                        isGrid ? Icons.grid_view : Icons.view_list,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          // Albüm kapağı karedir; metin bloğu için dikey
                          // pay bu oranda tutulur (orijinal değer korunur).
                          childAspectRatio: 0.72,
                        ),
                        itemCount: controller.albums.length,
                        itemBuilder: (context, i) {
                          final album = controller.albums[i];
                          return _AlbumCard(
                            album: album,
                            onTap: () => Get.toNamed<dynamic>(
                              AppRoutes.albumDetail,
                              arguments: album,
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          // Kompakt modda satırlar sıklaşır.
                          vertical: dense ? 4 : 8,
                        ),
                        itemExtent: dense ? 60.0 : 72.0,
                        itemCount: controller.albums.length,
                        itemBuilder: (context, i) {
                          final album = controller.albums[i];
                          return _AlbumTile(
                            album: album,
                            dense: dense,
                            onTap: () => Get.toNamed<dynamic>(
                              AppRoutes.albumDetail,
                              arguments: album,
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

/// Izgara kartı (orijinal _AlbumCard, davranış değişmeden korunur).
class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onTap});

  final AlbumModel album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ArtworkImage(
                  songId: album.artworkSongId,
                  borderRadius: BorderRadius.circular(16),
                  fallbackIcon: Icons.album_outlined,
                ),
                // Song count badge (alt-sağ)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.songCount(album.songCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title ?? l10n.unknownAlbum,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            album.artist ?? l10n.unknownArtist,
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

/// Görev 3.4: liste satırı. Kompakt modda kapak ve dolgu küçülür.
class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.album,
    required this.onTap,
    this.dense = false,
  });

  final AlbumModel album;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 4 : 8),
        child: Row(
          children: [
            ArtworkImage(
              songId: album.artworkSongId,
              size: dense ? 44 : 52,
              borderRadius: BorderRadius.circular(8),
              fallbackIcon: Icons.album_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    album.title ?? l10n.unknownAlbum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    album.artist ?? l10n.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.songCount(album.songCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
