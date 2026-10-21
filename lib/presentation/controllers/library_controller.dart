import 'package:get/get.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';

/// Kütüphane sekmelerinin veri kaynağı. Yalnızca [LibraryRepository]
/// soyutuna bağlıdır; datasource'u görmez.
class LibraryController extends GetxController {
  LibraryController(this._repository);

  final LibraryRepository _repository;

  // Şarkılar
  final songs = <SongModel>[].obs;
  final songSort = const SongSort().obs;
  final letterOffsets = <String, int>{}.obs;

  // Diğer gruplar
  final albums = <AlbumModel>[].obs;
  final artists = <ArtistModel>[].obs;
  final genres = <GenreModel>[].obs;
  final folders = <FolderModel>[].obs;

  // Durum
  final isLoading = true.obs;
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final sort = songSort.value;
      songs.value = await _repository.songs(sort: sort);
      letterOffsets.value = await _repository.letterOffsets(sort);
      albums.value = await _repository.albums();
      artists.value = await _repository.artists();
      genres.value = await _repository.genres();
      folders.value = await _repository.folders();
    } on Object {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setSongSort(SongSort sort) async {
    if (sort == songSort.value) return;
    songSort.value = sort;
    try {
      songs.value = await _repository.songs(sort: sort);
      letterOffsets.value = await _repository.letterOffsets(sort);
    } on Object {
      hasError.value = true;
    }
  }

  Future<void> rescan() async {
    await _repository.rescan();
    await loadAll();
  }

  // Detay sayfaları için salt okunur sorgular.
  Future<List<SongModel>> songsOfAlbum(int albumId) =>
      _repository.songsInAlbum(albumId);

  Future<List<SongModel>> songsOfArtist(int artistId) =>
      _repository.songsOfArtist(artistId);

  Future<List<AlbumModel>> albumsOfArtist(int artistId) =>
      _repository.albumsOfArtist(artistId);

  Future<List<SongModel>> songsInGenre(String genreKey) =>
      _repository.songsInGenre(genreKey);

  Future<List<FolderModel>> subfolders(String? parentPath) =>
      _repository.folders(parentPath: parentPath);

  Future<List<SongModel>> songsInFolder(
    String path, {
    bool recursive = false,
  }) =>
      _repository.songsInFolder(path, recursive: recursive);
}