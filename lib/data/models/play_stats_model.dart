
class PlayStatsModel {
  const PlayStatsModel({
    required this.totalPlays,
    required this.uniqueSongsPlayed,
    required this.topArtists,
    required this.topGenres,
  });

  final int totalPlays;
  final int uniqueSongsPlayed;
  final Map<String, int> topArtists; // Sanatçı Adı -> Çalma Sayısı
  final Map<String, int> topGenres;  // Tür Adı -> Çalma Sayısı
}