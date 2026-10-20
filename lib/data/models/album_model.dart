/// Bir albüm (şarkılardan türetilir). Model aynı zamanda domain nesnesidir.
class AlbumModel {
  const AlbumModel({
    required this.id,
    required this.songCount,
    required this.totalDurationMs,
    this.title,
    this.artist,
    this.artworkSongId,
  });

  /// Albüm etiketi olmayan şarkıların tek "bilinmeyen albüm" kovası.
  static const int unknownId = -1;

  /// MediaStore albüm kimliği; [unknownId] ise bilinmeyen albüm.
  final int id;

  /// Null: bilinmeyen albüm (UI yerelleştirilmiş metni gösterir).
  final String? title;

  /// Albümdeki en sık geçen sanatçı; hiç yoksa null.
  final String? artist;
  final int songCount;
  final int totalDurationMs;

  /// Kapak için örnek şarkı kimliği (bilinmeyen albümde null).
  final int? artworkSongId;

  bool get isUnknown => id == unknownId;
  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  @override
  bool operator ==(Object other) => other is AlbumModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
