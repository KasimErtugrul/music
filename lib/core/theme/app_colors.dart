import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan sabit renk değerleri.
/// Tüm renkler tema motoru tarafından `ThemeData`'ya enjekte edilir;
/// UI'da doğrudan `Colors.xxx` kullanılmaz.
abstract final class AppColors {
  /// Varsayılan Material 3 tohum rengi (mor).
  static const Color defaultSeed = Color(0xFF6750A4);

  /// Hazır tema paletlerinden biri için tohum rengi.
  static const List<Color> palette = <Color>[
    defaultSeed,
    Color(0xFF006A60), // teal
    Color(0xFF8B5000), // amber
    Color(0xFF984061), // pink
    Color(0xFF0061A4), // blue
    Color(0xFF6C4E00), // brown
  ];

  /// AMOLED siyah yüzey için kullanılan renk.
  static const Color amoledBlack = Color(0xFF000000);

  /// Normal koyu tema yüzeyi.
  static const Color darkSurface = Color(0xFF1C1B1F);
}