import 'package:get/get.dart';
import 'package:resonance/core/utils/debouncer.dart';
import 'package:resonance/data/repositories/library_repository.dart';

class AppSearchController extends GetxController {
  AppSearchController(this._repo);
  final LibraryRepository _repo;

  final query = ''.obs;
  final isLoading = false.obs;
  final results = Rxn<LibrarySearchResult>();
  
  final _debouncer = Debouncer(milliseconds: 400);

  @override
  void onClose() {
    _debouncer.dispose();
    super.onClose();
  }

  void onQueryChanged(String text) {
    query.value = text;
    
    if (text.trim().isEmpty) {
      results.value = null;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _debouncer.run(() => _performSearch(text));
  }

  Future<void> _performSearch(String text) async {
    if (text != query.value) return; // Sorgu değiştiyse eski aramayı iptal et
    
    try {
      final res = await _repo.search(text);
      results.value = res;
    } finally {
      if (text == query.value) {
        isLoading.value = false;
      }
    }
  }
}