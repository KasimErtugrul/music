import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class QueueController extends GetxController {
  QueueController(this._player);
  final PlayerController _player;

  PlayerController get player => _player;

  Future<void> playNext(int index) async {
    // Kuyruktaki belirli bir şarkıyı çalmak için PlayerController'ı kullan
    final song = _player.songQueue[index];
    await _player.playSong(song, queue: _player.songQueue.toList());
  }
}