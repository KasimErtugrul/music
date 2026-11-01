import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Merkezi günlükçü. Release modunda konsola (logcat) hiçbir şey yazmaz;
/// ileride bir telemetri kanalı (Sentry/Crashlytics) bağlanacaksa tek
/// nokta [onReport]'tur.
class AppLog {
  AppLog._();

  /// Yakalanan her hata buraya da iletilir (varsayılan: yok).
  static void Function(Object error, StackTrace? stack, String source)?
      onReport;

  /// Bilgi/hata ayıklama mesajı. Yalnızca debug modunda yazılır.
  static void d(String message) {
    if (kDebugMode) developer.log(message, name: 'resonance');
  }

  /// Yakalanan hata. Debug'ta konsola yazılır; her modda [onReport]'a gider.
  static void error(Object error, StackTrace? stack, {String source = ''}) {
    if (kDebugMode) {
      developer.log(
        'Hata${source.isEmpty ? '' : ' [$source]'}: $error',
        name: 'resonance',
        error: error,
        stackTrace: stack,
      );
    }
    try {
      onReport?.call(error, stack, source);
    } on Object {
      // Raporlayıcının kendi hatası uygulamayı etkilemez.
    }
  }
}
