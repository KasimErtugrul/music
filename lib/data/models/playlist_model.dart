class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.name,
    required this.songCount,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final int songCount;
  final DateTime updatedAt;
}