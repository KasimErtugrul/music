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

  /// Gün 11: sıralama akışının sözleşmesi. UI hamlesi (ReorderableListView
  /// onReorder) önce yerel durumda uygulanır — sürükleme geri bildirimi
  /// anında olmalı. Gün 9 raporunun kaydettiği boşluk: yazımdan sonra
  /// hiçbir tazeleme yoktu; repo yazımı hata alsa bile yerel durum yeni
  /// sırada kalıyordu (görünüm diskteki gerçek sıradan sessizce sapardı).
  /// Artık detay HER KOŞULDA veri tabanından yeniden okunur: başarıda
  /// görünüm DB gerçeğiyle örtüşür (getSongs'un kütüphane çözümlemesi de
  /// tazelenir), hatada yerel durum DB'deki eski sıraya geri sarılır.
  /// Repo hatası bugünkü gibi yukarı fırlar (davranış korunur); geri
  /// sarma finally'de yapıldığı için hata yutulmaz.
  Future<void> reorderSongs(int playlistId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final song = currentSongs.removeAt(oldIndex);
    currentSongs.insert(newIndex, song);
    try {
      await _repo
          .reorderSongs(playlistId, currentSongs.map((s) => s.id).toList());
    } finally {
      // DB gerçeği kazanır: başarıda görünüm DB sırasına yakınsar,
      // hatada yerel durum eski sıraya döner (sessiz sapma kapanır).
      await loadPlaylistDetail(playlistId);
    }
  }
}