import 'package:resonance/data/models/song_model.dart';

/// Tek bir şarkının çalma özeti (istatistik listeleri için).
class SongStatEntry {
  const SongStatEntry({required this.song, required this.playCount});
  final SongModel song;
  final int playCount;
}

/// Son çalma kaydı (geçmiş akışı için): şarkı + zaman damgası.
class RecentPlay {
  const RecentPlay({required this.song, required this.playedAt});
  final SongModel song;
  final DateTime playedAt;
}

class PlayStatsModel {
  const PlayStatsModel({
    required this.totalPlays,
    required this.uniqueSongsPlayed,
    required this.topArtists,
    required this.topGenres,
    this.totalListenMs = 0,
    this.weeklyCounts = const <int>[0, 0, 0, 0, 0, 0, 0],
    this.topSongs = const <SongStatEntry>[],
  });

  final int totalPlays;
  final int uniqueSongsPlayed;
  final Map<String, int> topArtists; // Sanatçı Adı -> Çalma Sayısı
  final Map<String, int> topGenres;  // Tür Adı -> Çalma Sayısı

  /// Dinlenen toplam süre: her çalma olayında parçanın tam süresi toplanır
  /// (parça sonuna kadar dinlenmemiş olabilir; standart yaklaşıklama).
  final int totalListenMs;

  /// Haftanın günlerine göre çalma sayıları. Dizin 0 = Pazartesi ... 6 = Pazar.
  final List<int> weeklyCounts;

  /// En çok dinlenen şarkılar (azalan, en fazla 5).
  final List<SongStatEntry> topSongs;
}
