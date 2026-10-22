import 'package:flutter/material.dart';
import 'package:resonance/core/theme/app_colors.dart';

/// Hazır tema paletleri. Her biri bir tohum rengi ve okunabilir bir ad taşır.
class ThemePreset {
  const ThemePreset({required this.id, required this.name, required this.seed});

  final String id;
  final String name;
  final Color seed;
}

abstract final class ThemePresets {
  static const List<ThemePreset> all = <ThemePreset>[
    ThemePreset(id: 'default', name: 'Default', seed: AppColors.defaultSeed),
    ThemePreset(id: 'teal', name: 'Teal', seed: Color(0xFF006A60)),
    ThemePreset(id: 'amber', name: 'Amber', seed: Color(0xFF8B5000)),
    ThemePreset(id: 'pink', name: 'Pink', seed: Color(0xFF984061)),
    ThemePreset(id: 'blue', name: 'Blue', seed: Color(0xFF0061A4)),
    ThemePreset(id: 'brown', name: 'Brown', seed: Color(0xFF6C4E00)),
  ];

  static ThemePreset? find(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}