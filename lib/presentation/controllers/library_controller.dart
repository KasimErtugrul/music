import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/album_model.dart';
import 'package:resonance/data/models/artist_model.dart';
import 'package:resonance/data/models/folder_model.dart';
import 'package:resonance/data/models/genre_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';

/// Kütüphane sekmelerinin veri kaynağı. Yalnızca [LibraryRepository]
/// soyutuna bağlıdır; datasource'u görmez.
///
/// Aşama 3: açılışta ve uygulama ön plana döndüğünde artımlı tarama yapar.
/// MediaStore sorgusu her açılışta zaten taze veri getirir; otomatik
/// taramanın asıl katkısı (a) USB üzerinden kopyalanan dosyaların platform
/// tarayıcısıyla MediaStore'a kazandırılması, (b) uygulama açıkken değişen
/// kütüphanenin canlı güncellenmesidir. Ayar: `scanOnStartup`
/// (Kitaplık ayarları) — kapalıysa hiçbir otomatik tarama yapılmaz,
/// kullanıcı manuel yenilemeyi kullanır.
class LibraryController extends GetxController with WidgetsBindingObserver {
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

  // Aşama 3: otomatik tarama sürüyor mu? Şu an UI sessiz kalır; alan,
  // ileride ince gösterge (ör. app bar pulu) gerekirse hazır olsun diye
  // açıktır ve akışı yeniden giriş (re-entrancy) koruması olarak kullanır.
  final isAutoScanning = false.obs;

  /// İki otomatik tarama arasındaki en kısa aralık. Ön plana sık dönüşler
  /// (bildirim, ekran kilidi, uygulama değiştirme) MediaStore sorgusu
  /// başlatmasın; açılış taraması da bu saati günceller.
  static const Duration minAutoScanInterval = Duration(minutes: 5);

  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// `scanOnStartup` tercihi canlı okunur: ayar değişince yeniden başlatma
  /// gerektirmez. PreferencesController yoksa (erken faz) varsayılan açıktır.
  bool get _autoScanEnabled {
    if (Get.isRegistered<PreferencesController>()) {
      return Get.find<PreferencesController>().library.value.scanOnStartup;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadAll().then((_) => _startupScan());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
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

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      await _repository.rescan();
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

  /// Ek-A: Min. süre filtresi gibi sıralamayı bozmayan değişikliklerde
  /// MediaStore'a dokunmadan (rescan'siz) şarkı listesini taze sorgular.
  /// Filtre değerinin değiştiğini repository kendisi görür ve sıralı liste
  /// önbelleğini geçersiz kılar; mevcut indeks üzerinden yeniden süzer.
  Future<void> reloadSongs() async {
    try {
      final sort = songSort.value;
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

  // ---------- Aşama 3: otomatik artımlı tarama ----------

  /// Açılış taraması: liste ilk kez çizildikten sonra arka planda çalışır.
  /// Platform tarayıcı tetiklenir (USB kopyası yeni dosyalar MediaStore'a
  /// kazandırılır), ardından fark kontrol edilir.
  Future<void> _startupScan() async {
    if (!_autoScanEnabled || hasError.value) return;
    _lastScanAt = DateTime.now();
    await autoScan(triggerPlatformScan: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_autoScanEnabled || hasError.value || isAutoScanning.value) return;
    if (DateTime.now().difference(_lastScanAt) < minAutoScanInterval) return;
    _lastScanAt = DateTime.now();
    unawaited(autoScan());
  }

  /// Artımlı taramayı çalıştırır. Değişiklik yoksa hiçbir liste yeniden
  /// kurulmaz ve UI kol darbesi yaşamaz; değişiklik varsa listeler sessizce
  /// tazelenir ve ekleme/silme kısa bir bilgiyle bildirilir. Başarısızlık
  /// kullanıcıyı rahatsız etmez (arka plan servisi davranışı).
  Future<void> autoScan({bool triggerPlatformScan = false}) async {
    if (isAutoScanning.value) return;
    isAutoScanning.value = true;
    try {
      final delta =
          await _repository.incrementalScan(triggerPlatformScan: triggerPlatformScan);
      if (delta.changed) {
        await _reloadLists();
        _announceDelta(delta);
      }
    } on Object {
      // Arka plan taraması başarısız olabilir; sonraki Resume'da yeniden denenir.
    } finally {
      isAutoScanning.value = false;
    }
  }

  /// Otomatik tarama sonrası listeleri yükleme göstergesi olmadan tazeler.
  /// isLoading'a dokunmaz: kullanıcı mevcut listeyi görmeye devam eder.
  Future<void> _reloadLists() async {
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
    }
  }

  /// Yalnızca ekleme/silme bildirilir; başlık-süre güncellemeleri sessizdir.
  void _announceDelta(LibraryScanDelta delta) {
    if (delta.added <= 0 && delta.removed <= 0) return;
    final context = Get.context;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    final parts = <String>[
      if (delta.added > 0) '+${delta.added}',
      if (delta.removed > 0) '−${delta.removed}',
    ];
    if (parts.isEmpty) return;
    Get.snackbar(
      l10n.libraryScanUpdated,
      parts.join('  ·  '),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
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
  }) => _repository.songsInFolder(path, recursive: recursive);
}
