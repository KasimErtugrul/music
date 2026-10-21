
import 'package:flutter/services.dart';
import 'package:resonance/core/errors/app_exception.dart';
import 'package:resonance/data/models/song_model.dart';

/// Cihazdaki müzikleri okuyan veri kaynağı.
///
/// Gün 3 kararı: kendi Kotlin MethodChannel'ımız (MediaStore). `on_audio_query_pluse`
/// Android 13+ cihazda yerel tarafta çöktüğü için elendi.
abstract class DeviceMediaDataSource {
  /// Karşılaştırma ekranı için kısa ad.
  String get name;

  /// Ses dosyalarını okur. Zil sesi / alarm / bildirim sesleri hariç tutulur.
  /// Filtreler (min. süre, format vb.) Gün 21'de eklenir.
  Future<List<SongModel>> querySongs();

  /// Şarkının gömülü/albüm kapağı (JPEG). Kapak yoksa veya okunamazsa null.
  Future<Uint8List?> queryArtwork(int songId, {int size = 200});
}

/// Kendi Kotlin MethodChannel'ımız ile doğrudan MediaStore.
/// Kotlin tarafı: `android/app/src/main/kotlin/.../MainActivity.kt`.
class MediaStoreChannelDataSource implements DeviceMediaDataSource {
  MediaStoreChannelDataSource({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'com.example.resonance/media_store';

  final MethodChannel _channel;

  @override
  String get name => 'MediaStore';

  @override
  Future<List<SongModel>> querySongs() async {
    try {
      final raw = await _channel
          .invokeListMethod<Map<Object?, Object?>>('querySongs');
      return (raw ?? const <Map<Object?, Object?>>[])
          .map(SongModel.fromMap)
          .toList(growable: false);
    } on Exception catch (e) {
      throw AppException(
        AppErrorCode.mediaQueryFailed,
        message: 'MediaStore channel querySongs failed',
        cause: e,
      );
    }
  }

  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 200}) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'queryArtwork',
        <String, Object>{'id': songId, 'size': size},
      );
    } on Exception {
      return null;
    }
  }
}
