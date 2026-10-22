import 'package:flutter/material.dart';
import 'package:resonance/core/theme/app_colors.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/font_registry.dart';

/// Tüm tema ayarlarını taşıyan model.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor = AppColors.defaultSeed,
    this.amoled = false,
    this.highContrast = false,
    this.surfaceTint = true,
    this.roundedCorners = true,
    this.density = VisualDensity.standard,
    this.fontFamily = 'Inter',
    this.textScale = 1.0,
    this.player = PlayerThemeExtension.defaults,
    this.listViewMode = 'comfortable',
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final bool amoled;
  final bool highContrast;
  final bool surfaceTint;
  final bool roundedCorners;
  final VisualDensity density;
  final String fontFamily;
  final double textScale;
  final PlayerThemeExtension player;
  final String listViewMode;

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool? amoled,
    bool? highContrast,
    bool? surfaceTint,
    bool? roundedCorners,
    VisualDensity? density,
    String? fontFamily,
    double? textScale,
    PlayerThemeExtension? player,
    String? listViewMode,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      amoled: amoled ?? this.amoled,
      highContrast: highContrast ?? this.highContrast,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      roundedCorners: roundedCorners ?? this.roundedCorners,
      density: density ?? this.density,
      fontFamily: fontFamily ?? this.fontFamily,
      textScale: textScale ?? this.textScale,
      player: player ?? this.player,
      listViewMode: listViewMode ?? this.listViewMode,
    );
  }
}

/// `ThemeSettings`'ten açık ve koyu `ThemeData` üretir.
abstract final class ThemeEngine {
  static ThemeData light(ThemeSettings s) => _build(s, Brightness.light);
  static ThemeData dark(ThemeSettings s) => _build(s, Brightness.dark);

  static ThemeData _build(ThemeSettings s, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Renk şeması: tohum rengi + parlaklık. AMOLED ve yüksek kontrast
    // `ColorScheme.fromSeed` üzerinden değil, ThemeData kopyalanarak uygulanır.
    final scheme = ColorScheme.fromSeed(
      seedColor: s.seedColor,
      brightness: brightness,
      contrastLevel: s.highContrast ? 1.0 : 0.0,
    );

    // AMOLED: koyu temada yüzeyleri tam siyah yap.
    final ColorScheme effectiveScheme;
    if (isDark && s.amoled) {
      effectiveScheme = scheme.copyWith(
        surface: AppColors.amoledBlack,
        surfaceContainerHighest: Color(0xFF121212),
        surfaceContainerHigh: Color(0xFF0A0A0A),
        surfaceContainerLow: Color(0xFF050505),
      );
    } else {
      effectiveScheme = scheme;
    }

    // Font ailesi + yazı tipi ölçeği.
    final fontEntry = FontRegistry.find(s.fontFamily);
    final baseTextTheme = isDark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    final textTheme = fontEntry != null
        ? baseTextTheme.apply(fontFamily: fontEntry.family)
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: effectiveScheme,
      textTheme: textTheme,
      visualDensity: s.density,
      // Yüzey tonlaması: M3'te `surfaceTint` rengi ile kontrol edilir.
      // Kapatmak için şeffaf yap.
      scaffoldBackgroundColor: effectiveScheme.surface,
      cardTheme: CardThemeData(
        color: effectiveScheme.surfaceContainerHighest,
        elevation: s.surfaceTint ? null : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 16 : 0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: effectiveScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 24 : 0),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: effectiveScheme.surfaceContainer,
        elevation: s.surfaceTint ? null : 0,
      ),
      extensions: <ThemeExtension<dynamic>>[s.player],
    );
  }
}