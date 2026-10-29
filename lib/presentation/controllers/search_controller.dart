import 'dart:convert';

import 'package:get/get.dart';
import 'package:resonance/core/utils/debouncer.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI tasarım güncellemesi: arama geçmişi eklendi. Son aramalar cihazda
/// (SharedPreferences) tutulur; en fazla [_historyMax] terim saklanır.
/// Kütüphane aramasının kendisi değişmedi: [LibraryRepository.search]
/// debouncer ile aynı şekilde çağrılır.
class AppSearchController extends GetxController {
  AppSearchController(this._repo);
  final LibraryRepository _repo;

  final query = ''.obs;
  final isLoading = false.obs;
  final results = Rxn<LibrarySearchResult>();

  /// Son aramalar (en yeni başta). Boşsa tasarımdaki boş duruma düşer.
  final searchHistory = <String>[].obs;

  SharedPreferences? _prefs;

  static const String _historyKey = 'search_history';
  static const int _historyMax = 8;

  final _debouncer = Debouncer(milliseconds: 400);

  @override
  void onInit() {
    super.onInit();
    try {
      _prefs = Get.find<SharedPreferences>();
    } on Object {
      // Prefs hazır değilse geçmiş sessizce devre dışı kalır; arama bozulmaz.
      _prefs = null;
    }
    _loadHistory();
  }

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

  /// Kullanıcı aramayı "gönderdiğinde" (klavyedeki ara tuşu veya sonuç
  /// öğesine dokunuş) terimi geçmişe kaydeder. Boş terim kaydedilmez.
  Future<void> commitSearch(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    searchHistory.remove(t);
    searchHistory.insert(0, t);
    while (searchHistory.length > _historyMax) {
      searchHistory.removeLast();
    }
    await _persistHistory();
  }

  Future<void> removeHistoryItem(String term) async {
    searchHistory.remove(term);
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    searchHistory.clear();
    await _persistHistory();
  }

  void _loadHistory() {
    final raw = _prefs?.getString(_historyKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .take(_historyMax)
          .toList();
      searchHistory.assignAll(list);
    } on Object {
      // Bozuk kayıt: geçmişi yok say.
    }
  }

  Future<void> _persistHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_historyKey, jsonEncode(searchHistory.toList()));
    } on Object {
      // Kalıcılık başarısız olsa bile oturumluk geçmiş çalışmaya devam eder.
    }
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
