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
    // Gün 3 (Karar): zamanlanmış koyu mod varsayılan KAPALI. Eski veride
    // anahtar yoksa geçiş kuralı fromJson'da uygulanır.
    this.scheduledDarkEnabled = false,
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

  /// Gün 3: zamanlanmış koyu mod anahtarı. Kapalıyken saat aralığı
  /// saklanır ama uygulanmaz.
  final bool scheduledDarkEnabled;
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
    bool? scheduledDarkEnabled,
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
      scheduledDarkEnabled: scheduledDarkEnabled ?? this.scheduledDarkEnabled,
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
      'scheduledDarkEnabled': scheduledDarkEnabled,
      'scheduledDarkStartHour': scheduledDarkStartHour,
      'scheduledDarkStartMinute': scheduledDarkStartMinute,
      'scheduledDarkEndHour': scheduledDarkEndHour,
      'scheduledDarkEndMinute': scheduledDarkEndMinute,
    };
  }

  /// Gün 3: alan-seviyesi güvenli ayrıştırma. Tek bozuk/eksik alan artık
  /// TÜM temayı sıfırlamaz (eski kod ThemeMode.values.byName ve Color(int)
  /// çağrılarında TypeError/ArgumentError fırlatıp loadActiveTheme'in
  /// catch'ine düşüyor, bütün ayarlar varsayılana dönüyordu); yalnız o
  /// alan varsayılana döner.
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    // num kabul eder (jsonDecode 0.0'ı double, 0'ı int üretir).
    double doubleOf(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    int intOf(String key, int fallback) {
      final v = json[key];
      return v is int ? v : fallback;
    }

    bool boolOf(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    String stringOf(String key, String fallback) {
      final v = json[key];
      return v is String ? v : fallback;
    }

    // Alt harita (player) için varyant — Gün 3: statik yardımcı değil,
    // kapsamı sınırlı yerel fonksiyon.
    String stringIn(Map<String, dynamic> map, String key, String fallback) {
      final v = map[key];
      return v is String ? v : fallback;
    }

    // themeMode: geçersiz isim tüm ayrıştırmayı bozmasın.
    final modeName = stringOf('themeMode', 'system');
    final themeMode = ThemeMode.values
        .where((m) => m.name == modeName)
        .firstOrNull ?? ThemeMode.system;

    // themeSource: beyaz liste dışı değer seed'e döner.
    final themeSource = switch (stringOf('themeSource', 'seed')) {
      'system' => 'system',
      'artwork' => 'artwork',
      _ => 'seed',
    };

    // seedColor: tip bozuksa (ör. string) varsayılan tohum.
    final seedRaw = json['seedColor'];
    final seedColor = seedRaw is int ? Color(seedRaw) : AppColors.defaultSeed;

    // textScale: tip bozuksa 1.0; aralık dışıysa 0.5–2.0'a kırpılır.
    final textScale = doubleOf('textScale', 1.0).clamp(0.5, 2.0).toDouble();

    // density: VisualDensity kurucusu |değer| <= 4 ister; kırp.
    final density = VisualDensity(
      horizontal: doubleOf('densityX', 0).clamp(-4, 4).toDouble(),
      vertical: doubleOf('densityY', 0).clamp(-4, 4).toDouble(),
    );

    // player: harita değilse (bozuk veri) tamamen varsayılan.
    final playerRaw = json['player'];
    final playerJson = playerRaw is Map<String, dynamic>
        ? playerRaw
        : const <String, dynamic>{};
    final player = PlayerThemeExtension(
      backgroundStyle: stringIn(playerJson, 'backgroundStyle', 'solid'),
      artworkShape: stringIn(playerJson, 'artworkShape', 'rounded'),
      seekBarStyle: stringIn(playerJson, 'seekBarStyle', 'classic'),
      miniPlayerStyle: stringIn(playerJson, 'miniPlayerStyle', 'compact'),
      animationLevel: stringIn(playerJson, 'animationLevel', 'full'),
    );

    // listViewMode: beyaz liste dışı değer comfortable'e döner.
    final listViewMode = switch (stringOf('listViewMode', 'comfortable')) {
      'compact' => 'compact',
      'grid' => 'grid',
      _ => 'comfortable',
    };

    final startHour = intOf('scheduledDarkStartHour', 20);
    final startMinute = intOf('scheduledDarkStartMinute', 0);
    final endHour = intOf('scheduledDarkEndHour', 7);
    final endMinute = intOf('scheduledDarkEndMinute', 0);

    // Gün 3 geçiş kuralı (Karar): 'scheduledDarkEnabled' anahtarı eski
    // veride yoktur. Bu durumda saklanan saat aralığı varsayılandan
    // (20:00–07:00) farklıysa kullanıcı zamanlamayı kurmuş sayılır → açık;
    // aralık varsayıansa kapalı. Anahtar varsa açıkça yazılan değer kazanır.
    final enabledRaw = json['scheduledDarkEnabled'];
    final scheduledDarkEnabled = enabledRaw is bool
        ? enabledRaw
        : startHour != 20 ||
            startMinute != 0 ||
            endHour != 7 ||
            endMinute != 0;

    return ThemeSettings(
      themeMode: themeMode,
      themeSource: themeSource,
      seedColor: seedColor,
      amoled: boolOf('amoled', false),
      highContrast: boolOf('highContrast', false),
      surfaceTint: boolOf('surfaceTint', true),
      roundedCorners: boolOf('roundedCorners', true),
      density: density,
      fontFamily: stringOf('fontFamily', 'Inter'),
      textScale: textScale,
      player: player,
      listViewMode: listViewMode,
      scheduledDarkEnabled: scheduledDarkEnabled,
      scheduledDarkStartHour: startHour,
      scheduledDarkStartMinute: startMinute,
      scheduledDarkEndHour: endHour,
      scheduledDarkEndMinute: endMinute,
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

    // Gün 3 (Karar): highContrast dinamik şemaya da uygulanır. OS paletinin
    // tonları birebir korunamaz; primary tohumundan M3 kontrast kademesi
    // 1.0 ile yeniden üretilir. Kapalıyken OS paleti aynen kullanılır.
    if (s.highContrast && dynamicScheme != null) {
      baseScheme = ColorScheme.fromSeed(
        seedColor: dynamicScheme.primary,
        brightness: brightness,
        contrastLevel: 1.0,
      );
    }

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
      // Gün 3: roundedCorners artık alt sayfa / snackbar / popup menüyü de
      // kapsar. Açıkken değerler M3 varsayılanlarıdır (28/4/4); kapalıyken
      // köşeler kare olur (0).
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(s.roundedCorners ? 28 : 0),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 4 : 0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.roundedCorners ? 4 : 0),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[s.player],
    );
  }
}