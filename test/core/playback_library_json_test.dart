// Gün 10 testi: PlaybackSettingsModel / LibrarySettingsModel.fromJson
// alan-seviyesi güvenli ayrıştırma — Gün 3'te ThemeSettings'e uygulanan
// desenin kalan yarısı (GUN1 raporu «Bozuk JSON içeren ayar dosyasının
// davranışı Gün 3/10'da (fromJson sağlamlaştırma)» diye kayıtlıydı) ve
// ölü gapless alanının kaldırılması sonrası eski-JSON uyumu.
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';

void main() {
  group('PlaybackSettingsModel.fromJson alan-seviyesi güvenlik (Gün 10)', () {
    test('geçerli JSON gidiş-dönüşünde tüm alanlar korunur', () {
      const model = PlaybackSettingsModel(
        seekIntervalSeconds: 30,
        autoResume: true,
        pauseOnHeadphone: false,
        defaultShuffle: true,
        defaultRepeat: 2,
        speed: 1.25,
        pitch: 0.5,
        skipSilence: true,
        replayGain: true,
      );
      final roundTrip = PlaybackSettingsModel.fromJson(model.toJson());
      expect(roundTrip.toJson(), model.toJson());
    });

    test('tek bozuk alan yalnız o alanı varsayılana döndürür', () {
      // Eski davranış: string speed → TypeError → PreferencesController
      // catch'i → TÜM çalma ayarları varsayılana dönüyordu.
      final model = PlaybackSettingsModel.fromJson(<String, dynamic>{
        'seekIntervalSeconds': 30,
        'speed': 'hızlı', // bozuk: string
        'autoResume': 'evet', // bozuk: bool değil
        'pitch': 2, // int kabul edilir (jsonDecode int üretir)
      });
      expect(model.seekIntervalSeconds, 30); // sağlam alan korunur
      expect(model.speed, 1.0); // yalnız bozuk alan varsayılana döner
      expect(model.autoResume, isFalse);
      expect(model.pitch, 2.0); // num kabulü (eski davranışla uyumlu)
    });

    test('ölü gapless alanı: eski JSON yok sayılır, toJson yazmaz', () {
      // Gün 2 bulgusu → Gün 10 kaldırma: hiçbir tüketici yoktu; just_audio
      // kesintisiz geçişi zaten sağlar. Eski yedek/prefs JSON'undaki
      // 'gapless' anahtarı bilinmeyen alan olarak akışı bozmaz:
      final model = PlaybackSettingsModel.fromJson(<String, dynamic>{
        'speed': 1.5,
        'gapless': false, // eski sürümün yazdığı alan
      });
      expect(model.speed, 1.5);
      expect(model.toJson().containsKey('gapless'), isFalse);
    });
  });

  group('LibrarySettingsModel.fromJson alan-seviyesi güvenlik (Gün 10)', () {
    test('geçerli JSON gidiş-dönüşünde tüm alanlar korunur', () {
      const model = LibrarySettingsModel(
        scanOnStartup: false,
        minDurationSeconds: 45,
      );
      final roundTrip = LibrarySettingsModel.fromJson(model.toJson());
      expect(roundTrip.toJson(), model.toJson());
    });

    test('tek bozuk alan yalnız o alanı varsayılana döndürür', () {
      final model = LibrarySettingsModel.fromJson(<String, dynamic>{
        'scanOnStartup': 1, // bozuk: bool değil
        'minDurationSeconds': 'otuz', // bozuk: string
      });
      expect(model.scanOnStartup, isTrue);
      expect(model.minDurationSeconds, 0);
    });
  });
}