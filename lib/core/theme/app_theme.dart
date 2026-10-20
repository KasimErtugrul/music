import 'package:flutter/material.dart';

/// GEÇİCİ tema (Gün 1). Gün 18'de `theme_engine.dart` ile değiştirilecek.
///
/// Tohum renk Material 3 baseline mor tonudur (tasarım paketindeki varsayılan
/// ile aynı); renkler `ColorScheme` üzerinden okunur, UI'da sabit renk yok.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF6750A4);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: brightness,
      ),
    );
  }
}
