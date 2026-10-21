import 'package:audio_service/audio_service.dart';

class QueueStateModel {
  const QueueStateModel({
    required this.songUris,
    required this.currentIndex,
    required this.position,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.shuffleOrder,
  });

  final List<String> songUris;
  final int currentIndex;
  final Duration position;
  final bool shuffleEnabled;
  final AudioServiceRepeatMode repeatMode;
  final List<int>? shuffleOrder;
}