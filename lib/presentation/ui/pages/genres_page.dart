import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

class GenresPage extends GetView<LibraryController> {
  const GenresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.songCount(controller.genres.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 112,
              ),
              itemCount: controller.genres.length,
              itemBuilder: (context, i) {
                final genre = controller.genres[i];
                return _GenreTile(
                  genre: genre,
                  index: i,
                  onTap: () => Get.toNamed<dynamic>(
                    AppRoutes.genreDetail,
                    arguments: genre,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({
    required this.genre,
    required this.onTap,
    required this.index,
  });

  final GenreModel genre;
  final VoidCallback onTap;
  final int index;

  // Renk rotasyonu: primary → secondary → tertiary → primary...
  (Color, IconData) _style(ThemeData theme) {
    final cs = theme.colorScheme;
    switch (index % 3) {
      case 0:
        return (cs.primary, Icons.headphones);
      case 1:
        return (cs.secondary, Icons.graphic_eq);
      default:
        return (cs.tertiary, Icons.piano);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (color, icon) = _style(theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  genre.name ?? l10n.unknownGenre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.songCount(genre.songCount),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}