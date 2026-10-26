import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class SongsView extends StatefulWidget {
  const SongsView({super.key});

  @override
  State<SongsView> createState() => _SongsViewState();
}

class _SongsViewState extends State<SongsView> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 76.0; // 72dp tile + 4dp padding

  void _scrollToLetter(String letter) {
    final controller = Get.find<LibraryController>();
    final index = controller.letterOffsets[letter];
    if (index == null) return;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * _itemHeight,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<LibraryController>();
    final playerCtrl = Get.find<PlayerController>();
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
        return EmptyState(
          icon: Icons.music_off_outlined,
          title: l10n.libraryEmptySongsTitle,
          message: l10n.libraryEmptySongsMessage,
          action: FilledButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.homeScanNow),
          ),
        );
      }

      return Column(
        children: <Widget>[
          _Header(
            onSort: controller.setSongSort,
            current: controller.songSort.value,
            total: controller.songs.length,
          ),
          const SizedBox(height: 8),
          _ActionButtons(songs: controller.songs, player: playerCtrl),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    Responsive.fromWidth(constraints.maxWidth) !=
                    WindowSize.compact;
                final listMode = themeCtrl.settings.value.listViewMode;
                final isListMode =
                    !(listMode == 'grid' || (isWide && listMode != 'compact'));

                if (!isListMode) {
                  // Grid Mode
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 76,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: controller.songs.length,
                    itemBuilder: (context, i) => SongTile(
                      song: controller.songs[i],
                      queueContext: controller.songs,
                    ),
                  );
                }

                // List Mode with Alphabet Scroller
                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 24, bottom: 100),
                      itemExtent: _itemHeight,
                      itemCount: controller.songs.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SongTile(
                          song: controller.songs[i],
                          queueContext: controller.songs,
                        ),
                      ),
                    ),
                    if (!isWide)
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 100,
                        child: _AlphabetScroller(
                          offsets: controller.letterOffsets,
                          onLetterSelected: _scrollToLetter,
                        ),
                      ),
                  ],
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

// ========== HEADER & ACTIONS ==========

class _Header extends StatelessWidget {
  const _Header({
    required this.onSort,
    required this.current,
    required this.total,
  });

  final ValueChanged<SongSort> onSort;
  final SongSort current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: <Widget>[
          Text(
            l10n.libraryTracksCount(total),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.libraryLosslessHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          PopupMenuButton<SongSort>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_by_alpha,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fieldLabel(l10n, current.field),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            tooltip: l10n.sortBy,
            onSelected: onSort,
            itemBuilder: (context) => <PopupMenuEntry<SongSort>>[
              _buildSortItem(
                context,
                SongSortField.title,
                SortDirection.ascending,
                l10n.sortByTitleAsc,
              ),
              _buildSortItem(
                context,
                SongSortField.artist,
                SortDirection.ascending,
                l10n.sortByArtist,
              ),
              _buildSortItem(
                context,
                SongSortField.album,
                SortDirection.ascending,
                l10n.sortByAlbum,
              ),
              _buildSortItem(
                context,
                SongSortField.dateAdded,
                SortDirection.descending,
                l10n.sortByDateAdded,
              ),
              _buildSortItem(
                context,
                SongSortField.duration,
                SortDirection.descending,
                l10n.sortByDuration,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SongSort> _buildSortItem(
    BuildContext context,
    SongSortField field,
    SortDirection dir,
    String label,
  ) {
    final sort = SongSort(field: field, direction: dir);
    final isSelected = current == sort;
    return PopupMenuItem<SongSort>(
      value: sort,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
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
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.songs, required this.player});

  final List<dynamic> songs;
  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.shuffle,
              label: l10n.shuffleAll,
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                if (songs.isNotEmpty) {
                  player.playSong(songs.first, queue: songs.cast());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.play_arrow,
              label: l10n.playInOrder,
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                if (songs.isNotEmpty) {
                  player.playSong(songs.first, queue: songs.cast());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== ALPHABET SCROLLER ==========

class _AlphabetScroller extends StatelessWidget {
  const _AlphabetScroller({
    required this.offsets,
    required this.onLetterSelected,
  });

  final Map<String, int> offsets;
  final ValueChanged<String> onLetterSelected;

  static const List<String> _alphabet = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'F',
    'G',
    'Ğ',
    'H',
    'I',
    'İ',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'Q',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      // Taşmayı önlemek için tüm sütunu mevcut alana ölçekle.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _alphabet.map((letter) {
            final isActive = offsets.containsKey(letter);
            return GestureDetector(
              onTap: () => onLetterSelected(letter),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
