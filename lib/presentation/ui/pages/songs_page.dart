import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class SongsView extends GetView<LibraryController> {
  const SongsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError.value) {
        return EmptyState(
          icon: Icons.error_outline,
          title: l10n.libraryLoadErrorTitle,
          message: l10n.libraryLoadErrorMessage,
          action: FilledButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
          ),
        );
      }
      if (controller.songs.isEmpty) {
        // Şarkı yokken "Yenile" butonu görünür.
        return EmptyState(
          icon: Icons.music_off_outlined,
          title: l10n.libraryEmptySongsTitle,
          message: l10n.libraryEmptySongsMessage,
          action: FilledButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        );
      }
      return Column(
        children: <Widget>[
          _SortHeader(
            onSort: controller.setSongSort,
            onRefresh: controller.refresh,
            current: controller.songSort.value,
            total: controller.songs.length,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = Responsive.fromWidth(constraints.maxWidth) !=
                    WindowSize.compact;
                final listMode = themeCtrl.settings.value.listViewMode;

                if (listMode == 'grid' || (isWide && listMode != 'compact')) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 72,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: controller.songs.length,
                    itemBuilder: (context, i) => SongTile(
                      song: controller.songs[i],
                      queueContext: controller.songs,
                    ),
                  );
                } else if (listMode == 'compact') {
                  return ListView.builder(
                    itemExtent: 56,
                    itemCount: controller.songs.length,
                    itemBuilder: (context, i) => SongTile(
                      song: controller.songs[i],
                      queueContext: controller.songs,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.songs.length,
                  itemBuilder: (context, i) => SongTile(
                    song: controller.songs[i],
                    queueContext: controller.songs,
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

class SongsPage extends StatelessWidget {
  const SongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.libraryTabSongs)),
      body: const SongsView(),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.onSort,
    required this.onRefresh,
    required this.current,
    required this.total,
  });

  final ValueChanged<SongSort> onSort;
  final VoidCallback onRefresh;
  final SongSort current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.songCount(total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRetry,
            onPressed: onRefresh,
          ),
          PopupMenuButton<SongSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBy,
            onSelected: onSort,
            itemBuilder: (context) => <PopupMenuEntry<SongSort>>[
              for (final field in SongSortField.values)
                for (final dir in SortDirection.values)
                  PopupMenuItem<SongSort>(
                    value: SongSort(field: field, direction: dir),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 20,
                          child: current ==
                                  SongSort(field: field, direction: dir)
                              ? const Icon(Icons.check, size: 16)
                              : null,
                        ),
                        Text(
                          '${_fieldLabel(l10n, field)} · ${_dirLabel(l10n, dir)}',
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _fieldLabel(AppLocalizations l10n, SongSortField f) {
    switch (f) {
      case SongSortField.title:
        return l10n.sortFieldTitle;
      case SongSortField.artist:
        return l10n.sortFieldArtist;
      case SongSortField.album:
        return l10n.sortFieldAlbum;
      case SongSortField.dateAdded:
        return l10n.sortFieldDateAdded;
      case SongSortField.duration:
        return l10n.sortFieldDuration;
    }
  }

  String _dirLabel(AppLocalizations l10n, SortDirection d) =>
      d == SortDirection.ascending ? l10n.sortAscending : l10n.sortDescending;
}