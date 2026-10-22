import 'package:flutter/material.dart';

/// Oynatıcıya özel tema değerlerini `ThemeData.extensions` üzerinden taşır.
/// `Theme.of(context).extension<PlayerThemeExtension>()!` ile erişilir.
@immutable
class PlayerThemeExtension extends ThemeExtension<PlayerThemeExtension> {
  const PlayerThemeExtension({
    required this.backgroundStyle,
    required this.artworkShape,
    required this.seekBarStyle,
    required this.miniPlayerStyle,
    required this.animationLevel,
  });

  /// `solid`, `gradient` veya `blur`.
  final String backgroundStyle;

  /// `square`, `rounded` veya `circle`.
  final String artworkShape;

  /// `classic`, `thin` veya `waveform` (dalga formu Gün 26'da etkinleşecek).
  final String seekBarStyle;

  /// `compact` veya `wide`.
  final String miniPlayerStyle;

  /// `full`, `reduced` veya `none`.
  final String animationLevel;

  /// Varsayılan değerler (tema motoru tarafından doldurulur).
  static const PlayerThemeExtension defaults = PlayerThemeExtension(
    backgroundStyle: 'solid',
    artworkShape: 'rounded',
    seekBarStyle: 'classic',
    miniPlayerStyle: 'compact',
    animationLevel: 'full',
  );

  @override
  PlayerThemeExtension copyWith({
    String? backgroundStyle,
    String? artworkShape,
    String? seekBarStyle,
    String? miniPlayerStyle,
    String? animationLevel,
  }) {
    return PlayerThemeExtension(
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      artworkShape: artworkShape ?? this.artworkShape,
      seekBarStyle: seekBarStyle ?? this.seekBarStyle,
      miniPlayerStyle: miniPlayerStyle ?? this.miniPlayerStyle,
      animationLevel: animationLevel ?? this.animationLevel,
    );
  }

  @override
  PlayerThemeExtension lerp(
    covariant ThemeExtension<PlayerThemeExtension>? other,
    double t,
  ) {
    // String alanlar için lerp anlamsızdır; anlık geçiş yapılır.
    if (other is! PlayerThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}