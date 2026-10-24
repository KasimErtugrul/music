class WaveformModel {
  final String songPath;
  final List<double> waveformData;
  final DateTime createdAt;

  const WaveformModel({
    required this.songPath,
    required this.waveformData,
    required this.createdAt,
  });
}