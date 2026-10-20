/// Bir sanatçı (şarkılardan türetilir).
class ArtistModel {
  const ArtistModel({
    required this.id,
    required this.songCount,
    required this.albumCount,
    required this.totalDurationMs,
    this.name,
    this.artworkSongId,
  });

  /// Sanatçı etiketi olmayan şarkıların tek "bilinmeyen sanatçı" kovası.
  static const int unknownId = -1;

  /// MediaStore sanatçı kimliği; [unknownId] ise bilinmeyen sanatçı.
  final int id;

  /// Null: bilinmeyen sanatçı.
  final String? name;
  final int songCount;

  /// Bilinmeyen albüm sayılmaz.
  final int albumCount;
  final int totalDurationMs;
  final int? artworkSongId;

  bool get isUnknown => id == unknownId;
  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  @override
  bool operator ==(Object other) => other is ArtistModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
