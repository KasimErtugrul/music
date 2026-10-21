import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  AlbumModel? _album;
  List<SongModel>? _songs;

  @override
  void initState() {
    super.initState();
    _album = Get.arguments as AlbumModel?;
    _load();
  }

  Future<void> _load() async {
    final album = _album;
    if (album == null) return;
    final songs = await Get.find<LibraryController>().songsOfAlbum(album.id);
    if (mounted) setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final album = _album;
    if (album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.libraryLoadErrorTitle,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          album.title ?? l10n.unknownAlbum,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 140,
                  height: 140,
                  child: ArtworkImage(
                    songId: album.artworkSongId,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: Icons.album_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        album.artist ?? l10n.unknownArtist,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.songCount(album.songCount)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _songs == null
                ? const Center(child: CircularProgressIndicator())
                : _songs!.isEmpty
                    ? EmptyState(
                        icon: Icons.music_off_outlined,
                        title: l10n.libraryEmptySongsTitle,
                      )
                    : ListView.builder(
                        itemCount: _songs!.length,
                        itemBuilder: (context, i) => SongTile(song: _songs![i]),
                      ),
          ),
        ],
      ),
    );
  }
}