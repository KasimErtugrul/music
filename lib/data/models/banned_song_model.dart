/// Gün 17 (Kasa): yasaklı şarkının kasa girdisi.
///
/// Alanlar diskteki dosyanın kopyası DEĞİLDİR; yalnızca kasa listesini
/// okunabilir tutan küçük bir anlık görüntüdür (başlık/sanatçı/albüm).
class BannedSongModel {
  final int id;
  final int songId;
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final DateTime createdAt;

  const BannedSongModel({
    required this.id,
    required this.songId,
    required this.path,
    required this.title,
    this.artist,
    this.album,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      other is BannedSongModel && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
