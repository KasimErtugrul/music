import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İçe aktarma sonucu. UI, sürüm uyuşmazlığını kullanıcının görebileceği bir
/// uyarıyla yüzeyler (şartname 7.13 uyumluluk banner'ı); artık sessiz
/// geçiştirilmez.
enum ImportStatus {
  success,
  versionMismatch,
  cancelled,
  failure,
}

class BackupController extends GetxController {
  BackupController(this._repo, this._libraryRepo);
  final BackupRepository _repo;
  final LibraryRepository _libraryRepo;

  final isLoading = false.obs;

  /// Son başarılı dışa aktarma zamanı (tasarımdaki "Son yedek" satırı).
  final lastBackupAt = Rxn<DateTime>();

  SharedPreferences? _prefs;
  static const String _kLastBackup = 'last_backup_at';

  @override
  void onInit() {
    super.onInit();
    try {
      _prefs = Get.find<SharedPreferences>();
    } on Object {
      _prefs = null;
    }
    final ms = _prefs?.getInt(_kLastBackup);
    if (ms != null && ms > 0) {
      lastBackupAt.value = DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }

  Future<bool> exportData(AppLocalizations l10n) async {
    isLoading.value = true;
    try {
      final data = await _repo.export();
      final jsonStr = jsonEncode(data.toJson());
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      // 1. Yol dene: FilePicker.saveFile
      try {
        final path = await FilePicker.saveFile(
          dialogTitle: 'Save backup',
          fileName: 'resonance_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (path != null) {
          await _markBackupDone();
          isLoading.value = false;
          return true;
        }
      } catch (e) {
        debugPrint('FilePicker.saveFile başarısız: $e');
      }

      // 2. Fallback: uygulama documents dizinine yaz
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/resonance_backup.json');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('Yedek şuraya yazıldı: ${file.path}');

      await _markBackupDone();
      isLoading.value = false;
      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      isLoading.value = false;
      return false;
    }
  }

  /// Kullanıcı dosya seçimi yaparsa ve içe aktarma tamamlanırsa
  /// [ImportStatus.success] / sürüm uyuşmazsa [ImportStatus.versionMismatch]
  /// döner. İptal ve hata ayrı durumlarla raporlanır; UI sessiz kalmaz.
  Future<ImportStatus> importData(AppLocalizations l10n) async {
    isLoading.value = true;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) {
        isLoading.value = false;
        return ImportStatus.cancelled;
      }

      final path = files.first.path;
      if (path == null) {
        isLoading.value = false;
        return ImportStatus.cancelled;
      }

      final file = File(path);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final backup = BackupModel.fromJson(json);

      final mismatch = backup.version != 1;
      await _repo.import(backup);
      await _libraryRepo.rescan();

      // Gün 1: içe aktarılan ayarlar canlı controller'lara yansıtılır;
      // kullanıcı uygulama yeniden başlatmadan güncel tercihler görür.
      await _reloadLiveControllers();

      isLoading.value = false;
      return mismatch ? ImportStatus.versionMismatch : ImportStatus.success;
    } catch (e) {
      debugPrint('Import error: $e');
      isLoading.value = false;
      return ImportStatus.failure;
    }
  }

  Future<void> _markBackupDone() async {
    final now = DateTime.now();
    lastBackupAt.value = now;
    final prefs = _prefs;
    if (prefs != null) {
      try {
        await prefs.setInt(_kLastBackup, now.millisecondsSinceEpoch);
      } on Object {
        // Kalıcılık başarısız olsa da oturumluk değer gösterilir.
      }
    }
  }

  /// Gün 1: içe aktarma sonrası ayar taşıyan canlı controller'ları yeniden
  /// yükler. Sıra önemlidir: EqualizerController.reload() içinden
  /// PreferencesController okunur; o yüzden önce tercihler tazelenir.
  /// Kayıtlı olmayan controller (ör. ilgili ekran hiç açılmadıysa) sessizce
  /// atlanır; tek bir reload hatası içe aktarmayı başarısız saymaz.
  Future<void> _reloadLiveControllers() async {
    await _reloadIfRegistered<PreferencesController>();
    await _reloadIfRegistered<ThemeController>();
    await _reloadIfRegistered<SettingsController>();
    await _reloadIfRegistered<EqualizerController>();
    await _reloadIfRegistered<HomeWidgetController>();
  }

  Future<void> _reloadIfRegistered<T extends GetxController>() async {
    if (!Get.isRegistered<T>()) return;
    try {
      await (Get.find<T>() as dynamic).reload();
    } on Object catch (e) {
      debugPrint('Reload başarısız ($T): $e');
    }
  }
}
