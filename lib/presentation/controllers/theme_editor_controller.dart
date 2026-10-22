import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class ThemeEditorController extends GetxController {
  ThemeEditorController(this._repo);
  final CustomThemeRepository _repo;

  final name = ''.obs;
  final settings = const ThemeSettings().obs;

  int? _editId;

  void initForEdit(CustomThemeModel theme) {
    _editId = theme.id;
    name.value = theme.name;
    settings.value = theme.settings;
  }

  Future<void> save() async {
    final trimmed = name.value.trim();
    if (trimmed.isEmpty) return;

    if (_editId != null) {
      await _repo.updateTheme(_editId!, trimmed, settings.value);
    } else {
      await _repo.saveTheme(trimmed, settings.value);
    }

    // Kaydettikten sonra aktif temayı hemen uygula.
    Get.find<ThemeController>().setSettings(settings.value);
  }

  void setSeedColor(int colorValue) {
    settings.value = settings.value.copyWith(seedColor: Color(colorValue));
  }

  void setAmoled(bool v) =>
      settings.value = settings.value.copyWith(amoled: v);

  void setHighContrast(bool v) =>
      settings.value = settings.value.copyWith(highContrast: v);
}