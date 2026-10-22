import 'dart:typed_data';
import 'package:flutter/material.dart';

abstract final class DynamicThemeService {
  static Future<ColorScheme?> fromArtwork(
    Uint8List bytes, {
    required Brightness brightness,
  }) async {
    try {
      return await ColorScheme.fromImageProvider(
        provider: MemoryImage(bytes),
        brightness: brightness,
      );
    } catch (_) {
      return null;
    }
  }
}