import 'package:flutter/material.dart';

/// Uygulamayla paketlenmiş fontların listesi.
/// Türkçe karakterleri (ç, ğ, ı, İ, ö, ş, ü) desteklediği test edilmelidir.
abstract final class FontRegistry {
  static const List<FontEntry> fonts = <FontEntry>[
    FontEntry(family: 'Inter', label: 'Inter'),
    FontEntry(family: 'PlusJakartaSans', label: 'Plus Jakarta Sans'),
    FontEntry(family: 'RobotoFlex', label: 'Roboto Flex'),
  ];

  static FontEntry? find(String family) {
    for (final f in fonts) {
      if (f.family == family) return f;
    }
    return null;
  }
}

class FontEntry {
  const FontEntry({required this.family, required this.label});

  /// `pubspec.yaml`'daki `family` adıyla eşleşmeli.
  final String family;

  /// UI'da gösterilecek okunabilir ad.
  final String label;

  TextStyle apply(TextStyle base) => base.copyWith(fontFamily: family);
}