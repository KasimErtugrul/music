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

class BackupController extends GetxController {
  final BackupRepository _repo;
  final LibraryRepository _libraryRepo;

  BackupController(this._repo, this._libraryRepo);

  final isLoading = false.obs;

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

      isLoading.value = false;
      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> importData(AppLocalizations l10n) async {
    isLoading.value = true;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) {
        isLoading.value = false;
        return false;
      }

      final path = files.first.path;
      if (path == null) {
        isLoading.value = false;
        return false;
      }

      final file = File(path);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final backup = BackupModel.fromJson(json);

      await _repo.import(backup);
      await _libraryRepo.rescan();

      isLoading.value = false;
      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      isLoading.value = false;
      return false;
    }
  }
}