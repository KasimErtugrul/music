import 'dart:io';
import 'package:haudiotagger/haudiotagger.dart';
import 'package:resonance/data/models/tag_model.dart';

class MetadataDatasource {
  Future<TagModel?> readTags(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final tag = await Haudiotagger.read(filePath);
      if (tag == null) return null;

      return TagModel(
        title: tag.title ?? '',
        artist: tag.trackArtist ?? '',
        album: tag.album ?? '',
        genre: tag.genre ?? '',
        year: tag.year?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}