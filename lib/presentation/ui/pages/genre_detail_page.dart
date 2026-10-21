import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class GenreDetailPage extends StatefulWidget {
  const GenreDetailPage({super.key});

  @override
  State<GenreDetailPage> createState() => _GenreDetailPageState();
}

class _GenreDetailPageState extends State<GenreDetailPage> {
  GenreModel? _genre;
  List<SongModel>? _songs;

  @override
  void initState() {
    super.initState();
    _genre = Get.arguments as GenreModel?;
    _load();
  }

  Future<void> _load() async {
    final genre = _genre;
    if (genre == null) return;
    final songs = await Get.find<LibraryController>().songsInGenre(genre.key);
    if (mounted) setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genre = _genre;
    if (genre == null) {
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
          genre.name ?? l10n.unknownGenre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _songs == null
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
    );
  }
}