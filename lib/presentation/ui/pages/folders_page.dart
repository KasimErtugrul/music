import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

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
          _Breadcrumb(path: _currentPath!, onTap: _load),
        const Divider(height: 1),
        Expanded(
          child: isEmpty
              ? EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: l10n.libraryEmptyFoldersTitle,
                  message: l10n.libraryEmptyFoldersMessage,
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  children: <Widget>[
                    if (_folders.isNotEmpty) ...<Widget>[
                      if (_currentPath != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                          child: Text(
                            l10n.folderSubfoldersTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      for (final f in _folders)
                        _FolderTile(
                          folder: f,
                          displayName: _displayName(f, l10n),
                          onTap: () => _load(f.path),
                        ),
                    ],
                    if (_songs.isNotEmpty) ...<Widget>[
                      if (_currentPath != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                          child: Text(
                            l10n.folderSongsTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      for (final s in _songs) SongTile(song: s),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  String _displayName(FolderModel f, AppLocalizations l10n) =>
      f.isVolumeRoot ? l10n.folderRootName : f.name;
}

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                folder.isVolumeRoot ? Icons.storage : Icons.folder,
                color: theme.colorScheme.primary,
                size: 22,
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.songCount(folder.songCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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

/// Tıklanabilir segment'lerle breadcrumb.
/// `/storage/emulated/0` → "Depolama" olarak gösterilir (tıklanınca köke döner).
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path, required this.onTap});

  final String path;
  final ValueChanged<String?> onTap;

  static final RegExp _volumeRe = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final match = _volumeRe.firstMatch(path);

    final List<Widget> segments = [];

    if (match == null) {
      segments.add(
        Flexible(
          child: Text(
            path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
      );
    } else {
      final root = match.group(0)!;
      final rest = path
          .substring(root.length)
          .split('/')
          .where((p) => p.isNotEmpty)
          .toList();

      // Kök segment
      segments.add(
        GestureDetector(
          onTap: rest.isEmpty ? null : () => onTap(root),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storage, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                l10n.folderRootName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: rest.isEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: rest.isEmpty ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

      var currentPath = root;
      for (var i = 0; i < rest.length; i++) {
        currentPath += '/${rest[i]}';
        final isLast = i == rest.length - 1;
        final segmentPath = currentPath;
        segments.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '/',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
        );
        segments.add(
          GestureDetector(
            onTap: isLast ? null : () => onTap(segmentPath),
            child: Text(
              rest[i],
              style: theme.textTheme.labelMedium?.copyWith(
                color: isLast
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            tooltip: l10n.backToParent,
            onPressed: () {
              final p = path;
              if (_volumeRe.hasMatch(p) &&
                  _volumeRe.firstMatch(p)!.group(0) == p) {
                onTap(null);
                return;
              }
              final slash = p.lastIndexOf('/');
              if (slash <= 0) {
                onTap(null);
                return;
              }
              onTap(p.substring(0, slash));
            },
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(children: segments),
            ),
          ),
        ],
      ),
    );
  }
}
