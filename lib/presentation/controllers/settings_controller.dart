import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_defaults.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/repositories/settings_repository.dart';

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

  Future<void> setThemeMode(String mode) async {
    final current = settings.value;
    if (current == null) return;
    final next = current.copyWith(themeMode: mode);
    settings.value = next;
    await _repo.setString(SettingsKeys.themeMode, mode);
    Get.changeThemeMode(_themeModeOf(mode));
  }

  Future<void> setDynamicColor(bool value) async {
    final current = settings.value;
    if (current == null) return;
    final next = current.copyWith(dynamicColor: value);
    settings.value = next;
    await _repo.setBool(SettingsKeys.dynamicColor, value);
  }

  Future<void> setAmoledDark(bool value) async {
    final current = settings.value;
    if (current == null) return;
    final next = current.copyWith(amoledDark: value);
    settings.value = next;
    await _repo.setBool(SettingsKeys.amoledDark, value);
  }

  ThemeMode get currentThemeMode =>
      _themeModeOf(settings.value?.themeMode ?? SettingsDefaults.themeMode);

  ThemeMode _themeModeOf(String mode) => switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}