import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_keys.dart';
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

  Future<void> setLanguage(String languageCode) async {
    final current = settings.value;
    if (current == null) return;
    final next = current.copyWith(languageCode: languageCode);
    settings.value = next;
    await _repo.setString(SettingsKeys.languageCode, languageCode);

    switch (languageCode) {
      case 'system':
        Get.updateLocale(Get.deviceLocale ?? const Locale('en'));
      case 'tr':
        Get.updateLocale(const Locale('tr'));
      case 'en':
        Get.updateLocale(const Locale('en'));
    }
  }
}