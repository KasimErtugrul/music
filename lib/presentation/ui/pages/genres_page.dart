import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class GenresPage extends GetView<LibraryController> {
  const GenresPage({super.key});

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
      if (controller.genres.isEmpty) {
        return EmptyState(
          icon: Icons.category_outlined,
          title: l10n.libraryEmptyGenresTitle,
          message: l10n.libraryEmptyGenresMessage,
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = Responsive.fromWidth(constraints.maxWidth) != WindowSize.compact;
          if (isWide) {
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: controller.genres.length,
              itemBuilder: (context, i) {
                final genre = controller.genres[i];
                return _GenreTile(
                  genre: genre,
                  onTap: () => Get.toNamed<dynamic>(
                    AppRoutes.genreDetail,
                    arguments: genre,
                  ),
                );
              },
            );
          }
          return ListView.builder(
            itemCount: controller.genres.length,
            itemBuilder: (context, i) {
              final genre = controller.genres[i];
              return _GenreTile(
                genre: genre,
                onTap: () => Get.toNamed<dynamic>(
                  AppRoutes.genreDetail,
                  arguments: genre,
                ),
              );
            },
          );
        },
      );
    });
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.genre, required this.onTap});

  final GenreModel genre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: ArtworkImage(
        songId: genre.artworkSongId,
        size: 48,
        borderRadius: BorderRadius.circular(8),
        fallbackIcon: Icons.category_outlined,
      ),
      title: Text(
        genre.name ?? l10n.unknownGenre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.songCount(genre.songCount)),
      onTap: onTap,
    );
  }
}