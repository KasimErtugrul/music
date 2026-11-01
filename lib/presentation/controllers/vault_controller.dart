import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/banned_song_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';

/// Gün 17 (Kasa): yasaklı şarkıların denetleyicisi.
///
/// Sorumlulukları:
/// - **Yasak indeksi:** [isBanned], oynatıcı korumasının (playSong guard)
///   O(1) son savunmasıdır; kümeler depo akışından canlı beslenir.
/// - **Ban/unban akışı:** kasa DB'ye yazar, istenirse çalma geçmişini
///   temizler, kütüphane indeksini HAM VERİDEN yeniler (MediaStore tekrar
///   sorgulanmaz) ve kütüphane denetleyicisinin Rx listelerini tazeler.
///   Böylece şarkı tüm ekranlardan anında düşer.
/// - **PIN kilidi:** kasa sayfasının kilidi. Cihaz tarafında hiçbir şey
///   yapılmaz (yeni eklenti/izin yok); PIN yalnızca Tuz + 5000 tur
///   SHA-256 ile özetlenmiş hâlde uygulama özel tercihlerinde tutulur.
///   5 hatalı denemeden sonra 30 saniyelik deneme kilidi devreye girer.
///
/// PIN unutulursa kurtarma yolu bilinçli olarak yoktur: yalnızca uygulama
/// verilerinin silinmesi kilidi kaldırır (kasa sayfasındaki notta yazar).
/// Ayar sıfırlaması da PIN'e dokunmaz — aksi hâlde kilidi gören herkes
/// «Tüm ayarları sıfırla» ile kilidi kaldırabilirdi.
class VaultController extends GetxController {
  VaultController(this._repo, this._historyRepo, this._libraryRepo, this._prefs);

  final BannedSongRepository _repo;
  final HistoryRepository _historyRepo;
  final LibraryRepository _libraryRepo;
  final SharedPreferences _prefs;

  static const String _kPinSalt = 'vault.pin.salt';
  static const String _kPinHash = 'vault.pin.hash';

  /// PIN özetleme turu. PIN uzayı kısa (4-6 hane) olduğu için ana koruma
  /// deneme kilididir; turlar çevrimdışı özet tahminini pahalılaştırır.
  static const int _kPinIterations = 5000;

  static const int _kMaxAttempts = 5;
  static const Duration _kLockDuration = Duration(seconds: 30);

  /// Kasa içeriği — kasa sayfası bunu dinler.
  final entries = <BannedSongModel>[].obs;

  /// Oynatıcı koruması için üyelik kümeleri (akıştan beslenir).
  Set<int> _bannedIds = <int>{};
  Set<String> _bannedPaths = <String>{};

  /// Kilit durumu. [isUnlocked] oturumla sınırlıdır: uygulama kapandığında
  /// doğal olarak yeniden kilitlenir.
  final hasPin = false.obs;
  final isUnlocked = false.obs;

  /// Üst üste hatalı PIN denemeleri ve deneme kilidinin biteceği an.
  final failedAttempts = 0.obs;
  final Rxn<DateTime> lockedUntil = Rxn<DateTime>();

  StreamSubscription<List<BannedSongModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _reloadSecurity();
    // Açılış yarışını kapatmak için akışın İLK değeri beklenmeden önce
    // kümeler bir kez doğrudan okunur; sonra canlı akış devralır.
    () async {
      try {
        final initial = await _repo.getBanned();
        _syncFrom(initial);
      } on Object {
        // Depo ilk okumada düşerse akış yine de güncel kümeleri getirecektir.
      }
    }();
    _sub = _repo.watchBanned().listen(_syncFrom, onError: (Object _) {});
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _syncFrom(List<BannedSongModel> list) {
    entries.assignAll(list);
    _bannedIds = {for (final e in list) e.songId};
    _bannedPaths = {for (final e in list) e.path};
  }

  /// Oynatıcı koruması: şarkı kasadaysa çalınamaz. Kütüphane indeksi de
  /// aynı kümelere göre süzdüğü için bu kontrol ikinci savunma hattıdır
  /// (kuyruk geri yükleme, harici açma niyeti gibi UI dışı yollara karşı).
  bool isBanned(SongModel song) =>
      _bannedPaths.contains(song.path) || _bannedIds.contains(song.id);

  /// Şarkıyı kasaya alır. Dosyaya hiçbir işlem yapılmaz; yalnızca indeks
  /// kaydı düşülür. [cleanHistory] doğruysa çalma geçmişi kayıtları da
  /// silinir (geçmiş sayfası başlık anlık görüntüsü sızdırmasın diye).
  Future<void> ban(SongModel song, {bool cleanHistory = true}) async {
    await _repo.ban(song);
    if (cleanHistory) {
      try {
        await _historyRepo.deleteHistoryForSong(song.id, song.path);
      } on Object {
        // Geçmiş silinemezse ban yine de geçerli olur; görüntüleme
        // tarafı zaten kütüphane filtresiyle temizdir.
      }
    }
    await _applyFilterChange();
  }

  /// Şarkıyı kasadan çıkarır; bir sonraki indeks yenilemesinde kütüphaneye
  /// geri döner (dosya diskte hep durduğu için ek işlem gerekmez).
  Future<void> unban(BannedSongModel entry) async {
    await _repo.unban(entry);
    await _applyFilterChange();
  }

  Future<void> _applyFilterChange() async {
    await _libraryRepo.refreshFilters();
    if (Get.isRegistered<LibraryController>()) {
      try {
        await Get.find<LibraryController>().loadAll();
      } on Object {
        // Kütüphane denetleyicisi henüz hazır değilse liste zaten ilk
        // yüklemede güncel indeksten kurulur.
      }
    }
  }

  // ---------- PIN kilidi ----------

  void _reloadSecurity() {
    hasPin.value = _prefs.getString(_kPinHash) != null;
    if (!hasPin.value) {
      isUnlocked.value = false;
      failedAttempts.value = 0;
      lockedUntil.value = null;
    }
  }

  /// Kilit ekranı deneme kilidinde mi? (canlı geri sayım için UI okur)
  bool get isLockedOut {
    final until = lockedUntil.value;
    return until != null && DateTime.now().isBefore(until);
  }

  /// PIN belirler (ilk kurulum). Doğruysa oturum açılır.
  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _prefs.setString(_kPinSalt, salt);
    await _prefs.setString(_kPinHash, _hash(pin, salt));
    hasPin.value = true;
    isUnlocked.value = true;
    failedAttempts.value = 0;
    lockedUntil.value = null;
  }

  /// PIN doğrular. Yanlışsa deneme sayacını işler; [_kMaxAttempts]
  /// hatadan sonra [_kLockDuration] süreli deneme kilidi başlatır.
  bool verifyPin(String pin) {
    if (isLockedOut) return false;
    final salt = _prefs.getString(_kPinSalt);
    final stored = _prefs.getString(_kPinHash);
    if (salt == null || stored == null) return false;
    if (_hash(pin, salt) == stored) {
      failedAttempts.value = 0;
      lockedUntil.value = null;
      isUnlocked.value = true;
      return true;
    }
    failedAttempts.value++;
    if (failedAttempts.value >= _kMaxAttempts) {
      lockedUntil.value = DateTime.now().add(_kLockDuration);
      failedAttempts.value = 0;
    }
    return false;
  }

  /// Kilidi yeniden kapatır (kasa sayfası kilit düğmesi).
  void lock() => isUnlocked.value = false;

  /// Deneme kilidinin kalan saniyesi (kilit yoksa 0).
  int get lockoutSecondsLeft {
    final until = lockedUntil.value;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inMilliseconds;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  static String _hash(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt\u0000resonance-vault\u0000$pin');
    for (var i = 0; i < _kPinIterations; i++) {
      bytes = crypto.sha256.convert(bytes).bytes;
    }
    return crypto.sha256.convert(bytes).toString();
  }

  static String _randomSalt() {
    final rnd = Random.secure();
    return List<String>.generate(
      16,
      (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
