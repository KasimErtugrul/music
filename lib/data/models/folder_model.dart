/// Müzik içeren bir klasör.
class FolderModel {
  const FolderModel({
    required this.path,
    required this.name,
    required this.songCount,
    required this.directSongCount,
    required this.totalDurationMs,
    required this.isVolumeRoot,
    this.parentPath,
  });

  /// Tam yol, sonunda `/` yok. Ör. `/storage/emulated/0/Music`.
  final String path;

  /// Yolun son parçası. Depolama kökünde ham ad (`0`, `1234-ABCD`); UI kökler
  /// için [isVolumeRoot] ile yerelleştirilmiş ad gösterir.
  final String name;

  /// Depolama kökünde null.
  final String? parentPath;

  /// Alt klasörler dahil toplam şarkı sayısı.
  final int songCount;

  /// Yalnızca bu klasörün doğrudan içindeki şarkılar.
  final int directSongCount;
  final int totalDurationMs;

  /// `/storage/emulated/0` veya `/storage/XXXX-XXXX` gibi depolama kökü.
  final bool isVolumeRoot;

  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  @override
  bool operator ==(Object other) => other is FolderModel && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
