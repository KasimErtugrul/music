
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

  /// Aşama 3: verilen klasörleri platform medya tarayıcısına bildirir.
  /// USB üzerinden kopyalanan yeni dosyaların MediaStore'a girmesini
  /// hızlandırır. Döndürülen değer tarayıcıya verilen dosya sayısıdır.
  /// Varsayılan no-op'tur; test sahteleri ve alternatif kaynaklar
  /// etkilenmez, yalnızca gerçek kanal kaynağı override eder.
  Future<int> triggerMediaScan(List<String> directories) async => 0;
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
      final songs = (raw ?? const <Map<Object?, Object?>>[])
          .map(SongModel.fromMap)
          .toList(growable: false);
      return _dedupeByPath(songs);
    } on Exception catch (e) {
      throw AppException(
        AppErrorCode.mediaQueryFailed,
        message: 'MediaStore channel querySongs failed',
        cause: e,
      );
    }
  }

  /// Gün 17.7: aynı dosya için çift MediaStore satırını tekilleştirir.
  ///
  /// MediaStore bazı durumlarda (MTP ile kopyalama, yedekten dönme, medya
  /// tarayıcısı yarışı) aynı `_data` yolunu farklı `_id` ile ikinci kez
  /// kaydedebilir. İki satır da kütüphaneye girer ve aynı dosya iki kez
  /// görünür; kasadan çıkarma akışında fark edildi — şarkı kasadayken yol
  /// filtresi her iki satırı da saklıyor, kasadan çıkınca ikisi birden
  /// ortaya çıkıyordu.
  ///
  /// Sözleşme: tek dosya = tek satır. Her yol İLK GÖRÜNDÜĞÜ konumda kalır;
  /// içeriği o yolun en güncel (en büyük `_id`) kaydıdır — kazanan satır
  /// kendi konumuna taşınmaz, aksi hâlde liste sırası sessizce değişirdi.
  /// Yol dosya kimliğidir: iki farklı dosyanın yolu aynı olamaz (aynı
  /// dosya iki hacimde duruyorsa yolları farklıdır ve her ikisi korunur).
  static List<SongModel> _dedupeByPath(List<SongModel> songs) {
    if (songs.length < 2) return songs;
    // 1. tur: yol -> en güncel kayıt (en büyük _id kazanır).
    final newestByPath = <String, SongModel>{};
    for (final s in songs) {
      final cur = newestByPath[s.path];
      if (cur == null || s.id > cur.id) newestByPath[s.path] = s;
    }
    if (newestByPath.length == songs.length) return songs; // kopya yok
    // 2. tur: her yol ilk göründüğü konumda, en güncel içerikle yayımlanır.
    final emitted = <String>{};
    return <SongModel>[
      for (final s in songs)
        if (emitted.add(s.path)) newestByPath[s.path]!,
    ];
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

  @override
  Future<int> triggerMediaScan(List<String> directories) async {
    try {
      return await _channel.invokeMethod<int>(
            'triggerMediaScan',
            <String, Object>{'paths': directories},
          ) ??
          0;
    } on Exception {
      return 0;
    }
  }
}