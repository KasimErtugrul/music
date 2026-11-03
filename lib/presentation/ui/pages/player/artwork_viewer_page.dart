import 'package:flutter/material.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

/// Bulgu 4: oynatıcı ekranındaki kapak resmine dokununca resim Hero
/// geçişiyle tam ekran açılır. Koyu zemin + InteractiveViewer ile
/// çift parmak yakınlaştırma ve kaydırma desteklenir; herhangi bir
/// dokunuş sayfayı kapatır.
class ArtworkViewerPage extends StatelessWidget {
  const ArtworkViewerPage({super.key, required this.song});

  final SongModel song;

  static Object tagOf(int songId) => 'artwork-viewer-$songId';

  static Future<void> show(BuildContext context, SongModel song) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ArtworkViewerPage(song: song),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: tagOf(song.id),
            child: InteractiveViewer(
              maxScale: 5,
              child: ArtworkImage(
                songId: song.id,
                fit: BoxFit.contain,
                fallbackIcon: Icons.music_note,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
