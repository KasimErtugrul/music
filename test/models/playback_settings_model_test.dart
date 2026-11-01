// Gün 20: PlaybackSettingsModel.fadeMs alanının kalıcılık sözleşmesi.
//
// Model, Gün 10'daki alan-seviyesi güvenli ayrışmayı kullanır: tek bozuk
// alan yalnız kendini varsayılana döndürür, bütün modeli sıfırlamaz.
// fadeMs için de aynı sözleşme burada sabitlenir; eski JSON'larda alan
// hiç olmadığından geriye dönük uyumluluk kritiktir.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/models/playback_settings_model.dart';

void main() {
  group('PlaybackSettingsModel fadeMs', () {
    test('varsayılan 0 (kapalı)', () {
      expect(const PlaybackSettingsModel().fadeMs, 0);
    });

    test('toJson/fromJson gidiş-dönüş değeri korur', () {
      const model = PlaybackSettingsModel(fadeMs: 500);
      final restored = PlaybackSettingsModel.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>,
      );
      expect(restored.fadeMs, 500);
      expect(restored.speed, model.speed);
      expect(restored.replayGain, model.replayGain);
    });

    test('eski JSONda alan yoksa varsayılana döner (geriye dönük uyum)', () {
      final legacy = PlaybackSettingsModel.fromJson(<String, dynamic>{
        'seekIntervalSeconds': 15,
        'speed': 1.25,
      });
      expect(legacy.fadeMs, 0);
      expect(legacy.seekIntervalSeconds, 15);
      expect(legacy.speed, 1.25);
    });

    test('bozuk fadeMs yalnız kendini sıfırlar, diğer alanlara dokunmaz', () {
      final corrupted = PlaybackSettingsModel.fromJson(<String, dynamic>{
        'fadeMs': 'hızlı', // tip uyuşmazlığı
        'skipSilence': true,
      });
      expect(corrupted.fadeMs, 0);
      expect(corrupted.skipSilence, isTrue);
    });
  });
}