import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/external_intent_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class ExternalOpenController extends GetxController {
  final ExternalIntentRepository _repo;
  final PlayerController _player;
  ExternalOpenController(this._repo, this._player);

  @override
  void onInit() {
    super.onInit();
    _handleInitial();
    _listen();
  }

  Future<void> _handleInitial() async {
    final uri = await _repo.getInitialUri();
    if (uri != null) _playUri(uri);
  }

  void _listen() {
    _repo.listenForNewIntents(_playUri);
  }

  void _playUri(String uri) async {
    // Harici dosya kütüphanede olmadığı için geçici bir SongModel oluşturuyoruz
    final tempSong = SongModel(
      id: uri.hashCode, // Geçici ID
      uri: uri,
      path: '', // Path yok, URI var
      title: 'External File',
      durationMs: 0,
      sizeBytes: 0,
    );

    // PlayerController'a tek şarkı çalmasını söylüyoruz
    await _player.playSong(tempSong);
    
    // Oynatıcı sayfasına yönlendir
    Get.toNamed(AppRoutes.player);
  }
}