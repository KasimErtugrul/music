import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class ArtistDetailPage extends StatefulWidget {
  const ArtistDetailPage({super.key});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  ArtistModel? _artist;
  List<SongModel>? _songs;

  @override
  void initState() {
    super.initState();
    _artist = Get.arguments as ArtistModel?;
    _load();
  }

  Future<void> _load() async {
    final artist = _artist;
    if (artist == null) return;
    final songs = await Get.find<LibraryController>().songsOfArtist(artist.id);
    if (mounted) setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final artist = _artist;
    if (artist == null) {
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
          artist.name ?? l10n.unknownArtist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                ArtworkImage(
                  songId: artist.artworkSongId,
                  size: 96,
                  borderRadius: BorderRadius.circular(48),
                  fallbackIcon: Icons.person_outline,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${l10n.songCount(artist.songCount)} • '
                    '${l10n.albumCount(artist.albumCount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
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