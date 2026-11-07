import 'package:get/get.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';

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
    await _applyLibraryChange(); // Kütüphaneyi güncelle
  }

  Future<void> removeFolder(String path) async {
    await _repo.removeFolder(path);
    await _load();
    await _applyLibraryChange(); // Kütüphaneyi güncelle
  }

  /// Bulgu 1: hariç tutulan klasör değişimi LibraryController'ın Rx
  /// listelerini TAZELEMİYORDU — rescan yalnız depo indeksini günceller,
  /// kütüphane sekmesi pull-to-refresh yapana kadar bayat listeyi
  /// gösteriyordu (Vault'un _applyFilterChange deseni buraya taşındı:
  /// isRegistered + loadAll). Hata akışı bozmaz; liste ilk yüklemede
  /// zaten güncel indeksten kurulur.
  Future<void> _applyLibraryChange() async {
    await _libraryRepo.rescan();
    if (Get.isRegistered<LibraryController>()) {
      try {
        await Get.find<LibraryController>().loadAll();
      } on Object {
        // Kütüphane denetleyicisi henüz hazır değilse liste ilk
        // yüklemede güncel indeksten kurulur.
      }
    }
  }
}