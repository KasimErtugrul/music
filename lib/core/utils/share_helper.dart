import 'package:share_plus/share_plus.dart';
import 'package:resonance/data/models/song_model.dart';

abstract final class ShareHelper {
  /// Şarkı bilgisini metin olarak paylaşır.
  /// Scoped storage kısıtlamaları nedeniyle dosyayı doğrudan paylaşmak
  /// yerine metin paylaşımı tercih edildi.
  static Future<void> shareSong(SongModel song) async {
    final artist = song.artist ?? 'Unknown Artist';
    final album = song.album ?? 'Unknown Album';
    final text = 'Listening to "${song.title}" by $artist (Album: $album)';
    
    await Share.share(text, subject: song.title);
  }
}