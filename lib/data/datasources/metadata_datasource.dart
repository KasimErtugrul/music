import 'dart:io';
import 'package:haudiotagger/haudiotagger.dart';
import 'package:resonance/data/models/song_model.dart';
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

  /// Şarkının REPLAYGAIN_TRACK_GAIN etiketini dB cinsinden döner
  /// (örn. "-6.43 dB" -> -6.43).
  ///
  /// Görev 2.3: Etiket yoksa, dosya yolu boşsa (path yalnızca MediaStore'dan
  /// gelir ve bazı kaynaklarda boş kalabilir) veya okuma başarısız olursa
  /// null döner. Bu metot ses akışını asla bozmamalıdır; tüm hatalar
  /// yutulur ve çağıran taraf 0 dB varsayar.
  ///
  /// Not: Etiket biçimi etiketleyiciye göre değişebilir ("-6.43 dB",
  /// "-6.43", "+2.10 dB"); sayısal olmayan karakterler temizlenir.
  /// haraudiotagger Tag sınıfı ReplayGain çerçevelerini (ID3v2 TXXX /
  /// Vorbis yorum) doğrudan destekler; ek paket gerekmez.
  Future<double?> replayGainDb(SongModel song) async {
    final path = song.path;
    if (path.isEmpty) return null;
    try {
      final tag = await Haudiotagger.read(path);
      if (tag == null) return null;
      final raw = tag.replayGainTrackGain;
      if (raw == null) return null;
      final cleaned = raw.replaceAll(RegExp(r'[^0-9.+\-]'), '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
