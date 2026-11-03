import 'package:get/get.dart';
import 'package:resonance/data/models/playlist_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class PlaylistController extends GetxController {
  PlaylistController(this._repo);
  final PlaylistRepository _repo;

  final playlists = <PlaylistModel>[].obs;
  final isLoading = true.obs;
  
  final currentPlaylist = Rxn<PlaylistModel>();
  final currentSongs = <SongModel>[].obs;

  /// Gün 21: şarkı kimliği -> içinde bulunduğu çalma listesi adları.
  /// Kütüphane sekmesindeki şarkı kartı «hangi listelerde» rozetini
  /// buradan okur. loadPlaylists her çağrıda haritayı da tazeler;
  /// ekle/çıkar/sil akışlarının tümü zaten loadPlaylists çağırdığı
  /// için ayrı bir dinleyiciye gerek yok.
  final playlistNamesBySong = RxMap<int, List<String>>();

  /// Gün 21: şarkının üyesi olduğu listeler; hiçbiri yoksa boş döner.
  /// SongTile'ın Obx'i içinde okunur — harita değişince rozetler
  /// kendiliğinden güncellenir.
  List<String> listNamesOf(int songId) =>
      playlistNamesBySong[songId] ?? const <String>[];

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    isLoading.value = true;
    try {
      playlists.assignAll(await _repo.getPlaylists());
      // Gün 21: üyelik haritası aynı tazelemede güncellenir.
      playlistNamesBySong.value = await _repo.playlistNamesBySong();
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

  /// Bulgu 2: şarkı zaten bu listedeyse ekleme YAPILMAZ ve false döner —
  /// çağıran arayüz kullanıcıyı snackbar ile bilgilendirir (sessiz
  /// başarısızlık kapatıldı). Diğer listelere ekleme her zaman serbesttir.
  Future<bool> addSongToPlaylist(int playlistId, SongModel song) async {
    final exists = await _repo.isSongInPlaylist(playlistId, song.id);
    if (exists) return false; // Zaten varsa ekleme
    await _repo.addSong(playlistId, song);
    await loadPlaylists();
    if (currentPlaylist.value?.id == playlistId) {
      await loadPlaylistDetail(playlistId);
    }
    return true;
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
  ///
  /// Gün 19: playlist'i LİSTE olarak çal — kuyruk playlist'in tamamıdır.
  ///
  /// Hata kaydı: detay sayfası salt bir düzenleyiciydi (satırlarda onTap
  /// yoktu, sayfada çal/karıştır düğmesi yoktu); oluşturulan playlist
  /// hiçbir yoldan liste olarak çalınamıyordu. Akıllı listelerdeki
  /// (SongTile queueContext) davranışın aynısı artık normal playlistlere
  /// de uygulanır; tek kaynak burası — detay sayfasındaki eylem kümesi
  /// de listeler sayfasındaki hızlı çal düğmesi de bu metodu çağırır.
  ///
  /// [shuffled] true ise karıştırma KAPALIYSA açılır ve rastgele bir
  /// parçayla başlanır (albüm/sanatçı detayındaki «Tümünü Karıştır»
  /// davranışının birebir aynısı). Zaten açıksa toggle çağrılmaz —
  /// kullanıcının mevcut modu korunur.
  ///
  /// Dönen değer: çalma başladıysa true. Boş playlistte hiçbir oynatıcı
  /// çağrısı yapılmaz ve false döner (kuyruk dokunulmaz). Şarkılar repo
  /// üzerinden taze çözümlenir (ID→path yeniden bağlama dahil); sayfada
  /// yüklenmiş kopyaya güvenilmez.
  Future<bool> playPlaylist(int id, {bool shuffled = false}) async {
    final songs = await _repo.getSongs(id);
    if (songs.isEmpty) return false;
    final player = Get.find<PlayerController>();
    if (shuffled && !player.shuffleEnabled.value) {
      await player.toggleShuffle();
    }
    final first = shuffled
        ? songs[DateTime.now().millisecond % songs.length]
        : songs.first;
    return player.playSong(first, queue: songs);
  }

  /// [newIndex] «çıkarma sonrası» konumdur: ReorderableListView.onReorderItem
  /// newIndex'i çıkarma için ÖNCEDEN düzeltir; burada tekrar -1 yapılırsa
  /// çift kayma olur. just_audio moveAudioSource da aynı sözleşmededir.
  Future<void> reorderSongs(int playlistId, int oldIndex, int newIndex) async {
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