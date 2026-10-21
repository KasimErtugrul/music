import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

/// Klasörler sekmesi: köklerden başlar, içine iner, breadcrumb ile geri.
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

  void _navigateUp() {
    final p = _currentPath;
    if (p == null) return;
    if (_isVolumeRoot(p)) {
      _load(null);
      return;
    }
    final slash = p.lastIndexOf('/');
    if (slash <= 0) {
      _load(null);
      return;
    }
    _load(p.substring(0, slash));
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
          _Breadcrumb(path: _currentPath!, onUp: _navigateUp),
        const Divider(height: 1),
        Expanded(
          child: isEmpty
              ? EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: l10n.libraryEmptyFoldersTitle,
                  message: l10n.libraryEmptyFoldersMessage,
                )
              : ListView(
                  children: <Widget>[
                    if (_folders.isNotEmpty) ...<Widget>[
                      if (_currentPath != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            l10n.folderSubfoldersTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      for (final f in _folders)
                        ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(
                            _displayName(f, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(l10n.songCount(f.songCount)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _load(f.path),
                        ),
                    ],
                    if (_songs.isNotEmpty) ...<Widget>[
                      if (_currentPath != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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

  bool _isVolumeRoot(String path) {
    final re = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)$');
    return re.hasMatch(path);
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path, required this.onUp});

  final String path;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: l10n.backToParent,
            onPressed: onUp,
          ),
          Expanded(
            child: Text(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}