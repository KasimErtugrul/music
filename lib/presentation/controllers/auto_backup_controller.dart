// Aşama 6: Otomatik yedekleme denetleyicisi.
//
// Zamanlama sözleşmesi: her uygulama açılışında main() ensureScheduledBackup()
// çağırır (fire-and-forget, açılışı bloklamaz). Son otomatik yedekten bu yana
// sıklık süresi (günlük/haftalık) dolduysa arka planda yedek alınır, ardından
// saklama politikası uygulanır. İlk açılışta (son yedek yok) hemen yedek alınır
// — kullanıcı kurulumdan itibaren korunur.
//
// Tercihler SettingsPersistence'taki açık anahtar listesiyle kalıcıya yazılır;
// manuel yedek (BackupDatasource) aynı listeden okuduğu için otomatik yedek
// AYARLARI da manuel yedeklere girer. Zamansal bağımlılıklar (`now`)
// enjekte edilebilir; testler sabit zamanla çalışır.
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Otomatik yedek sıklığı. Prefs'te string saklanır.
abstract class AutoBackupFrequency {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
}

class AutoBackupController extends GetxController {
  AutoBackupController({
    required AutoBackupRepository autoRepo,
    required BackupRepository backupRepo,
    required LibraryRepository libraryRepo,
    SharedPreferences? prefs,
    DateTime Function()? now,
  })  : _autoRepo = autoRepo,
        _backupRepo = backupRepo,
        _libraryRepo = libraryRepo,
        _prefs = prefs,
        _now = now ?? DateTime.now;

  final AutoBackupRepository _autoRepo;
  final BackupRepository _backupRepo;
  final LibraryRepository _libraryRepo;
  final SharedPreferences? _prefs;
  final DateTime Function() _now;

  // Gün 1: anahtarlar SettingsPersistence'tan gelir. _kLast bilinçli olarak
  // yedeklenmez (SettingsPersistence.notBackedUpKeys içinde).
  static const String _kEnabled = SettingsPersistence.autoBackupEnabled;
  static const String _kFrequency = SettingsPersistence.autoBackupFrequency;
  static const String _kKeep = SettingsPersistence.autoBackupKeep;
  static const String _kLast = SettingsPersistence.autoBackupLast;

  static const int defaultKeepCount = 7;

  /// UI'ın sunduğu saklama seçenekleri. Kalıcı tercihte geçersiz bir değer
  /// varsa (eski yedekten geri yükleme vb.) açılışta varsayılana döndürülür.
  static const List<int> keepChoices = <int>[3, 5, 7, 10];

  final enabled = true.obs;
  final frequency = AutoBackupFrequency.daily.obs;
  final keepCount = defaultKeepCount.obs;
  final lastRunAt = Rxn<DateTime>();

  /// En yeniden eskiye sıralı yedek kayıtları.
  final backups = RxList<AutoBackupEntry>([]);
  final isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    final p = _prefs;
    enabled.value = p?.getBool(_kEnabled) ?? true;
    final f = p?.getString(_kFrequency) ?? AutoBackupFrequency.daily;
    frequency.value =
        f == AutoBackupFrequency.weekly ? f : AutoBackupFrequency.daily;
    final k = p?.getInt(_kKeep) ?? defaultKeepCount;
    keepCount.value = keepChoices.contains(k) ? k : defaultKeepCount;
    final ms = p?.getInt(_kLast);
    if (ms != null && ms > 0) {
      lastRunAt.value = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    // Liste tazeleme; başarısızlık uygulama açılışını etkilemesin.
    refreshBackups();
  }

  /// Sıklık süresi dolduysa yedek alır. Hata fırlatmaz; runNow içinde
  /// yakalanır, buradaki tek görev kapıyı açmaktır.
  Future<void> ensureScheduledBackup() async {
    if (!enabled.value) return;
    final last = lastRunAt.value;
    if (last != null && _now().difference(last) < _interval()) return;
    await runNow();
  }

  Duration _interval() => frequency.value == AutoBackupFrequency.weekly
      ? const Duration(days: 7)
      : const Duration(days: 1);

  /// Kullanıcı "şimdi yedekle" dediğinde de çalışan tek yedekleme yolu.
  /// Sıklık kontrolü YOKTUR; başarıda son yedek zamanı kalıcıya yazılır ve
  /// saklama politikası uygulanır. Eşzamanlı ikinci çağrı reddedilir.
  Future<bool> runNow() async {
    if (isWorking.value) return false;
    isWorking.value = true;
    try {
      await _autoRepo.create();
      await _autoRepo.prune(keepCount.value);
      lastRunAt.value = _now();
      await _prefs?.setInt(_kLast, lastRunAt.value!.millisecondsSinceEpoch);
      await refreshBackups();
      return true;
    } on Object {
      debugPrint('AutoBackupController: yedekleme başarısız');
      return false;
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> refreshBackups() async {
    try {
      backups.assignAll(await _autoRepo.list());
    } on Object {
      debugPrint('AutoBackupController: yedek listesi okunamadı');
    }
  }

  /// Seçilen yedeği geri yükler: mevcut veri yedekle değiştirilir ve
  /// kütüphane yeniden taranır. Okuma bozuksa false döner, import yapılmaz.
  Future<bool> restore(AutoBackupEntry entry) async {
    if (isWorking.value) return false;
    isWorking.value = true;
    try {
      final model = await _autoRepo.read(entry);
      if (model == null) return false;
      await _backupRepo.import(model);
      await _libraryRepo.rescan();
      return true;
    } on Object {
      debugPrint('AutoBackupController: geri yükleme başarısız');
      return false;
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> deleteBackup(AutoBackupEntry entry) async {
    await _autoRepo.delete(entry);
    await refreshBackups();
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _prefs?.setBool(_kEnabled, value);
  }

  Future<void> setFrequency(String value) async {
    frequency.value = value == AutoBackupFrequency.weekly
        ? AutoBackupFrequency.weekly
        : AutoBackupFrequency.daily;
    await _prefs?.setString(_kFrequency, frequency.value);
  }

  Future<void> setKeepCount(int value) async {
    keepCount.value = keepChoices.contains(value) ? value : defaultKeepCount;
    await _prefs?.setInt(_kKeep, keepCount.value);
  }
}
