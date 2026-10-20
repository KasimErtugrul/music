/// Cihazdaki bir şarkı. Model aynı zamanda domain nesnesidir (entity yok).
///
/// Kimlik: MediaStore [id] tek başına kimlik sayılmaz; [path], [title],
/// [artist] ve [durationMs] de saklanır (Gün 13'te yeniden bağlama için).
class SongModel {
  const SongModel({
    required this.id,
    required this.uri,
    required this.path,
    required this.title,
    required this.durationMs,
    required this.sizeBytes,
    this.artist,
    this.album,
    this.genre,
    this.albumId,
    this.artistId,
    this.dateAdded,
  });

  /// MediaStore'un bilinmeyen etiketler için döndürdüğü metin.
  static const String unknownTag = '<unknown>';

  /// Boş veya `<unknown>` etiketi null yapar; UI yerelleştirilmiş "Bilinmeyen"
  /// metnini kendisi gösterir.
  static String? normalizeTag(String? value) {
    var v = value?.trim();
    // Bazı etiketlerin başında UTF-8 BOM (U+FEFF) kalıyor.
    if (v != null && v.startsWith('\uFEFF')) v = v.substring(1).trim();
    if (v == null || v.isEmpty || v == unknownTag) return null;
    return v;
  }

  /// Kanal (MethodChannel) haritasından üretir. Anahtarlar Kotlin tarafıyla
  /// aynıdır (`MainActivity.kt`).
  factory SongModel.fromMap(Map<Object?, Object?> map) {
    final displayName = map['displayName'] as String?;
    final dateSec = _asInt(map['dateAddedSec']);
    return SongModel(
      id: _asInt(map['id'])!,
      uri: map['uri']! as String,
      path: (map['path'] as String?) ?? '',
      title: normalizeTag(map['title'] as String?) ??
          _stripExtension(displayName) ??
          '',
      artist: normalizeTag(map['artist'] as String?),
      album: normalizeTag(map['album'] as String?),
      genre: normalizeTag(map['genre'] as String?),
      albumId: _asInt(map['albumId']),
      artistId: _asInt(map['artistId']),
      durationMs: _asInt(map['durationMs']) ?? 0,
      sizeBytes: _asInt(map['sizeBytes']) ?? 0,
      dateAdded: dateSec == null || dateSec <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dateSec * 1000),
    );
  }

  final int id;

  /// `content://` URI (çalma için).
  final String uri;

  /// Dosya yolu; boş olabilir.
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? albumId;
  final int? artistId;
  final int durationMs;
  final int sizeBytes;
  final DateTime? dateAdded;

  Duration get duration => Duration(milliseconds: durationMs);

  @override
  bool operator ==(Object other) =>
      other is SongModel && other.id == id && other.path == path;

  @override
  int get hashCode => Object.hash(id, path);

  static int? _asInt(Object? v) => v is num ? v.toInt() : null;

  static String? _stripExtension(String? name) {
    if (name == null || name.isEmpty) return null;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
