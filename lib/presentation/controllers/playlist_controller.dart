import 'package:get/get.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';

class PlaylistController extends GetxController {
  PlaylistController(this._repo);
  final PlaylistRepository _repo;

  final playlists = <PlaylistModel>[].obs;
  final isLoading = true.obs;
  
  final currentPlaylist = Rxn<PlaylistModel>();
  final currentSongs = <SongModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    isLoading.value = true;
    try {
      playlists.assignAll(await _repo.getPlaylists());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPlaylistDetail(int id) async {
    currentPlaylist.value = await _repo.getPlaylist(id);
    currentSongs.assignAll(await _repo.getSongs(id));
  }

  Future<void> createPlaylist(String name) async {
    await _repo.createPlaylist(name);
    await loadPlaylists();
  }

  Future<void> renamePlaylist(int id, String name) async {
    await _repo.renamePlaylist(id, name);
    await loadPlaylists();
    if (currentPlaylist.value?.id == id) {
      await loadPlaylistDetail(id);
    }
  }

  Future<void> deletePlaylist(int id) async {
    await _repo.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(int playlistId, SongModel song) async {
    final exists = await _repo.isSongInPlaylist(playlistId, song.id);
    if (exists) return; // Zaten varsa ekleme
    await _repo.addSong(playlistId, song);
    await loadPlaylists();
    if (currentPlaylist.value?.id == playlistId) {
      await loadPlaylistDetail(playlistId);
    }
  }

  Future<void> removeSong(int playlistId, int songId) async {
    await _repo.removeSong(playlistId, songId);
    await loadPlaylistDetail(playlistId);
    await loadPlaylists();
  }

  Future<void> reorderSongs(int playlistId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final song = currentSongs.removeAt(oldIndex);
    currentSongs.insert(newIndex, song);
    await _repo.reorderSongs(playlistId, currentSongs.map((s) => s.id).toList());
  }
}