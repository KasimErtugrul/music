import 'package:flutter/material.dart';
import 'package:resonance/core/theme/app_colors.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/theme/font_registry.dart';

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.themeSource = 'seed', // 'seed', 'system', 'artwork'
    this.seedColor = AppColors.defaultSeed,
    this.amoled = false,
    this.highContrast = false,
    this.surfaceTint = true,
    this.roundedCorners = true,
    this.density = VisualDensity.standard,
    this.fontFamily = 'Inter',
    this.textScale = 1.0,
    this.player = PlayerThemeExtension.defaults,
    this.listViewMode = 'comfortable', // 'compact', 'comfortable', 'grid'
    this.scheduledDarkStartHour = 20,
    this.scheduledDarkStartMinute = 0,
    this.scheduledDarkEndHour = 7,
    this.scheduledDarkEndMinute = 0,
  });

  final ThemeMode themeMode;
  final String themeSource;
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
  final int scheduledDarkStartHour;
  final int scheduledDarkStartMinute;
  final int scheduledDarkEndHour;
  final int scheduledDarkEndMinute;

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    String? themeSource,
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
    int? scheduledDarkStartHour,
    int? scheduledDarkStartMinute,
    int? scheduledDarkEndHour,
    int? scheduledDarkEndMinute,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      themeSource: themeSource ?? this.themeSource,
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
      scheduledDarkStartHour: scheduledDarkStartHour ?? this.scheduledDarkStartHour,
      scheduledDarkStartMinute: scheduledDarkStartMinute ?? this.scheduledDarkStartMinute,
      scheduledDarkEndHour: scheduledDarkEndHour ?? this.scheduledDarkEndHour,
      scheduledDarkEndMinute: scheduledDarkEndMinute ?? this.scheduledDarkEndMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'themeSource': themeSource,
      'seedColor': seedColor.value,
      'amoled': amoled,
      'highContrast': highContrast,
      'surfaceTint': surfaceTint,
      'roundedCorners': roundedCorners,
      'densityX': density.horizontal,
      'densityY': density.vertical,
      'fontFamily': fontFamily,
      'textScale': textScale,
      'player': {
        'backgroundStyle': player.backgroundStyle,
        'artworkShape': player.artworkShape,
        'seekBarStyle': player.seekBarStyle,
        'miniPlayerStyle': player.miniPlayerStyle,
        'animationLevel': player.animationLevel,
      },
      'listViewMode': listViewMode,
      'scheduledDarkStartHour': scheduledDarkStartHour,
      'scheduledDarkStartMinute': scheduledDarkStartMinute,
      'scheduledDarkEndHour': scheduledDarkEndHour,
      'scheduledDarkEndMinute': scheduledDarkEndMinute,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    final playerJson = json['player'] as Map<String, dynamic>? ?? {};
    return ThemeSettings(
      themeMode: ThemeMode.values.byName(json['themeMode'] ?? 'system'),
      themeSource: json['themeSource'] ?? 'seed',
      seedColor: Color(json['seedColor'] ?? AppColors.defaultSeed.value),
      amoled: json['amoled'] ?? false,
      highContrast: json['highContrast'] ?? false,
      surfaceTint: json['surfaceTint'] ?? true,
      roundedCorners: json['roundedCorners'] ?? true,
      density: VisualDensity(
        horizontal: json['densityX'] ?? 0,
        vertical: json['densityY'] ?? 0,
      ),
      fontFamily: json['fontFamily'] ?? 'Inter',
      textScale: (json['textScale'] ?? 1.0).toDouble(),
      player: PlayerThemeExtension(
        backgroundStyle: playerJson['backgroundStyle'] ?? 'solid',
        artworkShape: playerJson['artworkShape'] ?? 'rounded',
        seekBarStyle: playerJson['seekBarStyle'] ?? 'classic',
        miniPlayerStyle: playerJson['miniPlayerStyle'] ?? 'compact',
        animationLevel: playerJson['animationLevel'] ?? 'full',
      ),
      listViewMode: json['listViewMode'] ?? 'comfortable',
      scheduledDarkStartHour: json['scheduledDarkStartHour'] ?? 20,
      scheduledDarkStartMinute: json['scheduledDarkStartMinute'] ?? 0,
      scheduledDarkEndHour: json['scheduledDarkEndHour'] ?? 7,
      scheduledDarkEndMinute: json['scheduledDarkEndMinute'] ?? 0,
    );
  }
}

abstract final class ThemeEngine {
  static ThemeData light(ThemeSettings s, {ColorScheme? dynamicScheme}) => 
      _build(s, Brightness.light, dynamicScheme);
      
  static ThemeData dark(ThemeSettings s, {ColorScheme? dynamicScheme}) => 
      _build(s, Brightness.dark, dynamicScheme);

  static ThemeData _build(ThemeSettings s, Brightness brightness, ColorScheme? dynamicScheme) {
    final isDark = brightness == Brightness.dark;

    // Dinamik şema varsa onu kullan, yoksa seed renginden üret
    var baseScheme = dynamicScheme ?? ColorScheme.fromSeed(
      seedColor: s.seedColor,
      brightness: brightness,
      contrastLevel: s.highContrast ? 1.0 : 0.0,
    );

    // Primary rengi her durumda canlı tut (soft görünümü kır)
    final primary = dynamicScheme?.primary ?? s.seedColor;
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white : Colors.black;
    
    final primaryContainer = dynamicScheme?.primaryContainer ?? Color.lerp(
      primary, isDark ? Colors.black : Colors.white, isDark ? 0.55 : 0.75,
    )!;
    
    final onPrimaryContainer = dynamicScheme?.onPrimaryContainer ?? 
        (ThemeData.estimateBrightnessForColor(primaryContainer) == Brightness.dark ? Colors.white : Colors.black);

    var scheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
    );

    if (isDark && s.amoled) {
      scheme = scheme.copyWith(
        surface: AppColors.amoledBlack,
        surfaceContainerHighest: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF0A0A0A),
        surfaceContainerLow: const Color(0xFF050505),
      );
    }

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
      colorScheme: scheme,
      textTheme: textTheme,
      visualDensity: s.density,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: s.surfaceTint ? null : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 16 : 0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 24 : 0),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        elevation: s.surfaceTint ? null : 0,
        indicatorColor: scheme.primaryContainer,
      ),
      extensions: <ThemeExtension<dynamic>>[s.player],
    );
  }
}