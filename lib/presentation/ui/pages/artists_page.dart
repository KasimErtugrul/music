import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class ArtistsPage extends GetView<LibraryController> {
  const ArtistsPage({super.key});

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
      if (controller.artists.isEmpty) {
        return EmptyState(
          icon: Icons.person_outline,
          title: l10n.libraryEmptyArtistsTitle,
          message: l10n.libraryEmptyArtistsMessage,
        );
      }
      return ListView.builder(
        itemCount: controller.artists.length,
        itemBuilder: (context, i) {
          final artist = controller.artists[i];
          return _ArtistTile(
            artist: artist,
            onTap: () => Get.toNamed<dynamic>(
              AppRoutes.artistDetail,
              arguments: artist,
            ),
          );
        },
      );
    });
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist, required this.onTap});

  final ArtistModel artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: ArtworkImage(
        songId: artist.artworkSongId,
        size: 48,
        borderRadius: BorderRadius.circular(24),
        fallbackIcon: Icons.person_outline,
      ),
      title: Text(
        artist.name ?? l10n.unknownArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${l10n.songCount(artist.songCount)} • '
        '${l10n.albumCount(artist.albumCount)}',
      ),
      onTap: onTap,
    );
  }
}