import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';

/// Gün 17.8: Kitaplık sekmelerinin hap düğmeleri (Şarkılar/Albümler/…).
///
/// Sayaçlar [LibraryController] üzerindeki Rx listelerden Obx ile okunur:
/// kütüphane yüklenince veya kasa filtresi değişince rozetler KENDİLİĞİNDEN
/// güncellenir. Eskiden sayılar sayfa ilk kurulurken bir kez okunduğu için
/// açılışta «Şarkılar 0» yazısı, yükleme bitse bile kullanıcı bir sekmeye
/// dokunana dek donuk kalıyordu.
///
/// Seçim vurgusu [TabController] dinleyicisiyledir: dokunuşla YANİ SIRA
/// kaydırma (TabBarView swipe) ile yapılan geçişlerde de doğru çizilir.
class LibraryTabPills extends StatefulWidget {
  const LibraryTabPills({
    super.key,
    required this.controller,
    required this.tabController,
  });

  final LibraryController controller;
  final TabController tabController;

  @override
  State<LibraryTabPills> createState() => _LibraryTabPillsState();
}

class _LibraryTabPillsState extends State<LibraryTabPills> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant LibraryTabPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController.removeListener(_onTabChanged);
      widget.tabController.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctrl = widget.controller;
    return Obx(() {
      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _pill(0, l10n.libraryTabSongs, Icons.music_note, ctrl.songs.length, theme),
          _pill(1, l10n.libraryTabAlbums, Icons.album, ctrl.albums.length, theme),
          _pill(2, l10n.libraryTabArtists, Icons.person, ctrl.artists.length, theme),
          _pill(3, l10n.libraryTabGenres, Icons.category, ctrl.genres.length, theme),
          _pill(4, l10n.libraryTabFolders, Icons.folder, ctrl.folders.length, theme),
        ],
      );
    });
  }

  Widget _pill(
    int index,
    String label,
    IconData icon,
    int count,
    ThemeData theme,
  ) {
    final isSelected = widget.tabController.index == index;
    return GestureDetector(
      onTap: () => widget.tabController.animateTo(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                        .withValues(alpha: 0.7)
                    : theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}