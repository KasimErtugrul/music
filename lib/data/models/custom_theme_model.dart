import 'package:resonance/core/theme/theme_engine.dart';

class CustomThemeModel {
  const CustomThemeModel({
    required this.id,
    required this.name,
    required this.settings,
  });

  final int id;
  final String name;
  final ThemeSettings settings;
}