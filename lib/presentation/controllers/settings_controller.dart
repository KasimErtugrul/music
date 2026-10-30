import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/repositories/settings_repository.dart';

/// Yalnızca dil ayarını yönetir. Tema ayarları `ThemeController`'da.
class SettingsController extends GetxController {
  SettingsController(this._repo);
  final SettingsRepository _repo;

  final settings = Rxn<AppSettingsModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    settings.value = await _repo.load();
    isLoading.value = false;
  }

  /// Gün 1: yedek içe aktarma sonrası dil tercihini yeniden okur ve yerelini
  /// günceller; uygulama yeniden başlatmadan dil değişir.
  Future<void> reload() async {
    final loaded = await _repo.load();
    settings.value = loaded;
    _applyLocale(loaded.languageCode);
  }

  void _applyLocale(String languageCode) {
    switch (languageCode) {
      case 'system':
        Get.updateLocale(Get.deviceLocale ?? const Locale('en'));
      case 'tr':
        Get.updateLocale(const Locale('tr'));
      case 'en':
        Get.updateLocale(const Locale('en'));
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final current = settings.value;
    if (current == null) return;
    final next = current.copyWith(languageCode: languageCode);
    settings.value = next;
    // Gün 8: anahtar kimliği SettingsPersistence'tan (yük tarafıyla aynı
    // tek doğruluk kaynağı); SettingsKeys arayüz kimliği katmanıdır.
    await _repo.setString(SettingsPersistence.languageCode, languageCode);

    _applyLocale(languageCode);
  }
}