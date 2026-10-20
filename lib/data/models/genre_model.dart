/// Bir tür (şarkılardan türetilir). Aynı türün farklı yazımları
/// ("Rock" / "rock") tek türde birleşir.
class GenreModel {
  const GenreModel({
    required this.key,
    required this.songCount,
    required this.totalDurationMs,
    this.name,
    this.artworkSongId,
  });

  /// Türkçe küçük harfe çevrilmiş ad; bilinmeyen tür için boş metin.
  final String key;

  /// İlk görülen yazım; null: bilinmeyen tür.
  final String? name;
  final int songCount;
  final int totalDurationMs;
  final int? artworkSongId;

  bool get isUnknown => key.isEmpty;
  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  @override
  bool operator ==(Object other) => other is GenreModel && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
