import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/theme_engine.dart';

class ThemeController extends GetxController {
  final settings = const ThemeSettings().obs;

  ThemeData get lightTheme => ThemeEngine.light(settings.value);
  ThemeData get darkTheme => ThemeEngine.dark(settings.value);
  ThemeMode get themeMode => settings.value.themeMode;

  void setMode(ThemeMode mode) =>
      settings.value = settings.value.copyWith(themeMode: mode);

  void setSeed(Color color) =>
      settings.value = settings.value.copyWith(seedColor: color);

  void setAmoled(bool value) =>
      settings.value = settings.value.copyWith(amoled: value);

  void setHighContrast(bool value) =>
      settings.value = settings.value.copyWith(highContrast: value);

  void setSurfaceTint(bool value) =>
      settings.value = settings.value.copyWith(surfaceTint: value);

  void setRoundedCorners(bool value) =>
      settings.value = settings.value.copyWith(roundedCorners: value);

  void setDensity(VisualDensity density) =>
      settings.value = settings.value.copyWith(density: density);

  void setFont(String family) =>
      settings.value = settings.value.copyWith(fontFamily: family);

  void setTextScale(double scale) =>
      settings.value = settings.value.copyWith(textScale: scale);

  void setPlayer(PlayerThemeExtension player) =>
      settings.value = settings.value.copyWith(player: player);

  void setListViewMode(String mode) =>
      settings.value = settings.value.copyWith(listViewMode: mode);
}