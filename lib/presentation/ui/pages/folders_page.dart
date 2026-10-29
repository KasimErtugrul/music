import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

/// Klasörler gezgini — M3 tasarım güncellemesi:
/// - Yatay kaydırılabilir dizin hiyerarşisi çipleri (kök + klasör segmentleri,
///   bulunduğun klasör ikincil-konteyner dolgusuyla vurgulu)
/// - Klasör içi hero kartı: ad, gerçek şarkı sayısı + toplam süre, aksiyon
///   kümesi (Klasörü Çal / Karıştır / Gizle — şartname 6.8)
/// - Gizle: gerçek hariç-tutulan-klasör kaydı + yeniden tarama; snackbar'daki
///   "Geri Al" kaydı silip kütüphaneyi geri getirir
/// - Alt klasörler (ada göre sıralama düğmesi) + doğrudan ses dosyaları
/// - Alt özet çipi: gerçek alt klasör ve şarkı toplamları
///
/// Not: Tasarımdaki "Hi-Res Audio" ve dosya boyutu ("1.2 GB") rozetleri,
/// klasör düzeyinde kodlama/boyut verisi olmadığı için bilinçli olarak
/// eklenmedi; süre ve sayı bilgileri gerçek veridir.
class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  String? _currentPath;
  List<FolderModel> _folders = const <FolderModel>[];
  List<SongModel> _songs = const <SongModel>[];
  bool _loading = true;
  bool _hasError = false;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _load(null);
  }

  Future<void> _load(String? path) async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final ctrl = Get.find<LibraryController>();
      final folders = await ctrl.subfolders(path);
      final songs = path == null
          ? const <SongModel>[]
          : await ctrl.songsInFolder(path);
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _folders = folders;
        _songs = songs;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  List<FolderModel> get _sortedFolders {
    final list = List<FolderModel>.of(_folders);
    list.sort((a, b) {
      final ka = _displayName(a).toLowerCase();
      final kb = _displayName(b).toLowerCase();
      return _sortAscending ? ka.compareTo(kb) : kb.compareTo(ka);
    });
    return list;
  }

  String _displayName(FolderModel f) {
    final l10n = AppLocalizations.of(context);
    return f.isVolumeRoot ? l10n.folderRootName : f.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.libraryLoadErrorTitle,
        message: l10n.libraryLoadErrorMessage,
        action: FilledButton(
          onPressed: () => _load(_currentPath),
          child: Text(l10n.commonRetry),
        ),
      );
    }

    final isEmpty = _folders.isEmpty && _songs.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_currentPath != null)
          _BreadcrumbChips(path: _currentPath!, onTap: _load),
        Expanded(
          child: isEmpty
              ? EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: l10n.libraryEmptyFoldersTitle,
                  message: l10n.libraryEmptyFoldersMessage,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: <Widget>[
                    if (_currentPath != null) ...<Widget>[
                      _FolderHeroCard(
                        path: _currentPath!,
                        directSongCount: _songs.length,
                        folders: _folders,
                        songs: _songs,
                        onPlay: () => _playCurrentFolder(shuffle: false),
                        onShuffle: () => _playCurrentFolder(shuffle: true),
                        onHide: () => _hideFolder(context),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_folders.isNotEmpty) ...<Widget>[
                      _SectionHeader(
                        icon: Icons.folder_copy_outlined,
                        title: l10n.folderSubfoldersTitle,
                        count: _folders.length,
                        trailing: IconButton(
                          tooltip: l10n.sortBy,
                          icon: Icon(
                            _sortAscending
                                ? Icons.text_rotate_up
                                : Icons.text_rotate_vertical,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () =>
                              setState(() => _sortAscending = !_sortAscending),
                        ),
                      ),
                      for (final f in _sortedFolders)
                        _FolderTile(
                          folder: f,
                          displayName: _displayName(f),
                          onTap: () => _load(f.path),
                        ),
                    ],
                    if (_songs.isNotEmpty) ...<Widget>[
                      _SectionHeader(
                        icon: Icons.audio_file_outlined,
                        title: l10n.folderSongsTitle,
                        count: _songs.length,
                      ),
                      for (final s in _songs)
                        SongTile(song: s, queueContext: _songs),
                    ],
                    if (_currentPath != null) _SummaryChip(folders: _folders),
                  ],
                ),
        ),
      ],
    );
  }

  /// Klasörü çal / karıştır: alt klasörler dahil (özyinelemeli) tüm şarkılar.
  Future<void> _playCurrentFolder({required bool shuffle}) async {
    final path = _currentPath;
    if (path == null) return;
    final ctrl = Get.find<LibraryController>();
    final player = Get.find<PlayerController>();
    final l10n = AppLocalizations.of(context);
    final songs = await ctrl.songsInFolder(path, recursive: true);
    if (songs.isEmpty || !mounted) return;
    if (shuffle && !player.shuffleEnabled.value) {
      await player.toggleShuffle();
    }
    final first = shuffle
        ? songs[DateTime.now().millisecond % songs.length]
        : songs.first;
    await player.playSong(first, queue: songs);
    Get.snackbar(
      l10n.folderPlay,
      l10n.songCount(songs.length),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Şartname 6.8: klasörü kütüphaneden gizle. Gerçek hariç tutma kaydı +
  /// yeniden tarama; snackbar "Geri Al" kaydı kaldırıp kütüphaneyi tazeler.
  Future<void> _hideFolder(BuildContext context) async {
    final path = _currentPath;
    if (path == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.folderHide),
        content: Text(l10n.folderHideConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final parent = _parentOf(path);
    await Get.find<ExcludedFoldersController>().addFolder(path);
    if (!mounted) return;
    // Gizlenen klasörün içinden üst dizine çık.
    if (parent != null) await _load(parent);
    Get.snackbar(
      l10n.folderHiddenToast,
      path,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () async {
          await Get.find<ExcludedFoldersController>().removeFolder(path);
        },
        child: Text(l10n.folderUndo),
      ),
    );
  }

  static String? _parentOf(String path) {
    final slash = path.lastIndexOf('/');
    if (slash <= 0) return null;
    return path.substring(0, slash);
  }
}

// ========== DİZİN HİYERARŞİSİ ÇİPLERİ ==========

/// Tıklanabilir segment çipleriyle breadcrumb. Tasarımdaki yatay kaydırılabilir
/// hiyerarşi şeridi: kök "Depolama" çipi + klasör çipleri; son segment
/// secondary-container dolgusuyla vurgulanır.
class _BreadcrumbChips extends StatelessWidget {
  const _BreadcrumbChips({required this.path, required this.onTap});

  final String path;
  final ValueChanged<String?> onTap;

  static final RegExp _volumeRe = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final match = _volumeRe.firstMatch(path);

    final List<Widget> chips = [];

    if (match == null) {
      chips.add(_CrumbChip(
        label: path,
        active: true,
        onTap: null,
      ));
    } else {
      final root = match.group(0)!;
      final rest = path
          .substring(root.length)
          .split('/')
          .where((p) => p.isNotEmpty)
          .toList();

      chips.add(_CrumbChip(
        icon: Icons.smartphone,
        label: l10n.folderRootName,
        active: rest.isEmpty,
        onTap: rest.isEmpty ? null : () => onTap(root),
      ));

      var currentPath = root;
      for (var i = 0; i < rest.length; i++) {
        chips.add(Icon(Icons.chevron_right,
            size: 16, color: cs.outlineVariant));
        currentPath += '/${rest[i]}';
        final isLast = i == rest.length - 1;
        final segmentPath = currentPath;
        chips.add(_CrumbChip(
          icon: isLast ? Icons.folder_open : Icons.folder_outlined,
          label: rest[i],
          active: isLast,
          onTap: isLast ? null : () => onTap(segmentPath),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.folderHierarchyLabel.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (final c in chips) ...[
                    c,
                    if (c != chips.last) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrumbChip extends StatelessWidget {
  const _CrumbChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: active ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== KLASÖR HERO KARTI ==========

class _FolderHeroCard extends StatelessWidget {
  const _FolderHeroCard({
    required this.path,
    required this.directSongCount,
    required this.folders,
    required this.songs,
    required this.onPlay,
    required this.onShuffle,
    required this.onHide,
  });

  final String path;
  final int directSongCount;
  final List<FolderModel> folders;
  final List<SongModel> songs;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onHide;

  String get _folderName => path.split('/').where((p) => p.isNotEmpty).last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Gerçek toplam süre: doğrudan şarkılardan + alt klasör toplamlarından.
    final totalMs = songs.fold<int>(0, (sum, s) => sum + s.durationMs) +
        folders.fold<int>(0, (sum, f) => sum + f.totalDurationMs);
    final d = Duration(milliseconds: totalMs);
    final durationText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.album, color: cs.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _folderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.songCount(directSongCount)} • $durationText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: Text(
                      l10n.folderPlay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: FilledButton.tonalIcon(
                    onPressed: onShuffle,
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: Text(
                      l10n.shuffleAll,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FilledButton.tonalIcon(
                    onPressed: onHide,
                    icon: const Icon(Icons.visibility_off, size: 19),
                    label: Text(
                      l10n.folderHide,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: cs.surfaceContainerHigh,
                      foregroundColor: cs.onSurfaceVariant,
                    ),
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

// ========== BÖLÜM BAŞLIĞI ==========

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title ($count)',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ========== KLASÖR SATIRI ==========

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.displayName,
    required this.onTap,
  });

  final FolderModel folder;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    folder.isVolumeRoot ? Icons.storage : Icons.folder,
                    color: cs.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.songCount(folder.songCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== ÖZET ÇİPİ ==========

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.folders});
  final List<FolderModel> folders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final totalSongs = folders.fold<int>(0, (sum, f) => sum + f.songCount);
    final totalMs = folders.fold<int>(0, (sum, f) => sum + f.totalDurationMs);
    final d = Duration(milliseconds: totalMs);
    final durationText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.data_usage, size: 15, color: cs.primary),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  l10n.folderSummary(folders.length, totalSongs, durationText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
