import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/alphabet_scroller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class SongsView extends StatefulWidget {
  const SongsView({super.key});

  @override
  State<SongsView> createState() => _SongsViewState();
}

class _SongsViewState extends State<SongsView> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 88.0; // 84dp zengin kart + 4dp padding

  void _scrollToLetter(String letter) {
    final controller = Get.find<LibraryController>();
    final index = controller.letterOffsets[letter];
    if (index == null) return;

    if (_scrollController.hasClients) {
      // Bulgu 1: hedef, kaydırma aralığının sonuna taşarsa animateTo
      // zaten kenara kestiği için liste asla «boşa» gitmez; açık clamp
      // yine de tutarlılığı garanti eder.
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        (index * _itemHeight).clamp(0.0, max),
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
          // Bulgu 8: eski iki satırlık başlık (sayfa başlığı + iki büyük
          // eylem düğmesi ≈ 82dp) tek sıkışık satıra indirildi; liste
          // alanı ~40dp kazanır.
          _CompactHeader(
            onSort: controller.setSongSort,
            current: controller.songSort.value,
            total: controller.songs.length,
            player: playerCtrl,
            songs: controller.songs,
          ),
          const SizedBox(height: 4),
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
                          mainAxisExtent: 88,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: controller.songs.length,
                    itemBuilder: (context, i) => SongTile(
                      song: controller.songs[i],
                      queueContext: controller.songs,
                      height: 84,
                      // Gün 21: kütüphane kartı üyelik rozetini gösterir.
                      showPlaylistBadge: true,
                      // Zengin kart: codec / bit hızı / tür künye şeridi.
                      detailed: true,
                    ),
                  );
                }

                // List Mode with Alphabet Scroller
                final showScroller =
                    !isWide && controller.letterOffsets.isNotEmpty;
                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 24, bottom: 32),
                      itemExtent: _itemHeight,
                      itemCount: controller.songs.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SongTile(
                          song: controller.songs[i],
                          queueContext: controller.songs,
                          height: 84,
                          // Gün 21: kütüphane kartı üyelik rozetini gösterir.
                          showPlaylistBadge: true,
                          // Zengin kart: codec / bit hızı / tür künye şeridi.
                          detailed: true,
                        ),
                      ),
                    ),
                    if (showScroller)
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 32,
                        // Alfabe şeridi ayrı dosyada taşınmıştır:
                        // widgets/alphabet_scroller.dart (test edilebilir
                        // public widget; RenderFlex taşması garantili
                        // engelli — ölçü taraması testiyle kilitli).
                        child: AlphabetScroller(
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

// ========== TEK SATIRLIK SIKIŞIK BAŞLIK (Bulgu 8) ==========

/// Eski [_Header] + [_ActionButtons] ikilisinin yerini alan tek satır:
/// [toplam · ipucu] ... [karıştır] [sırayla çal] [sıralama].
/// İki büyük 44dp düğme yerine 36dp yuvarlak ikon düğmeleri kullanılır;
/// «Tümünü Karıştır» / «Sırayla Çal» etiketleri tooltip'e taşındı.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.onSort,
    required this.current,
    required this.total,
    required this.player,
    required this.songs,
  });

  final ValueChanged<SongSort> onSort;
  final SongSort current;
  final int total;
  final PlayerController player;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
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
                color: cs.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.libraryLosslessHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          _RoundAction(
            icon: Icons.shuffle,
            tooltip: l10n.shuffleAll,
            color: cs.primary,
            onTap: () {
              if (songs.isNotEmpty) {
                player.playSong(songs.first, queue: songs.cast<SongModel>());
              }
            },
          ),
          const SizedBox(width: 4),
          _RoundAction(
            icon: Icons.play_arrow,
            tooltip: l10n.playInOrder,
            color: cs.secondary,
            onTap: () {
              if (songs.isNotEmpty) {
                player.playSong(songs.first, queue: songs.cast<SongModel>());
              }
            },
          ),
          const SizedBox(width: 4),
          PopupMenuButton<SongSort>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_by_alpha, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    _fieldLabel(l10n, current.field),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
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

/// Bulgu 8: «Tümünü Karıştır» / «Sırayla Çal» için 36dp yuvarlak tonal
/// ikon düğmesi (etiket tooltip'te).
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
