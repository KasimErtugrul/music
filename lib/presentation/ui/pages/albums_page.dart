import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class AlbumsPage extends GetView<LibraryController> {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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
      );
    });
  }
}

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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ArtworkImage(
                  songId: album.artworkSongId,
                  borderRadius: BorderRadius.circular(12),
                  fallbackIcon: Icons.album_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title ?? l10n.unknownAlbum,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            album.artist ?? l10n.unknownArtist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            l10n.songCount(album.songCount),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}