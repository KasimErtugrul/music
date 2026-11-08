import 'package:get/get.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';

class ExcludedFoldersController extends GetxController {
  final ExcludedFolderRepository _repo;
  final LibraryRepository _libraryRepo;
  
  ExcludedFoldersController(this._repo, this._libraryRepo);

  final folders = <ExcludedFolderModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      folders.assignAll(await _repo.getExcludedFolders());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addFolder(String path) async {
    await _repo.addFolder(path);
    await _load();
    await _libraryRepo.rescan(); // Kütüphaneyi güncelle
  }

  Future<void> removeFolder(String path) async {
    await _repo.removeFolder(path);
    await _load();
    await _libraryRepo.rescan(); // Kütüphaneyi güncelle
  }
}