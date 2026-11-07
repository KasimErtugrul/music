// FAZ 5 (Bulgu 6/12) testleri: ekolayzer yazım disiplini.
//
// Bulgu 6: Slider sürükleme tiki artık yalnız DONANIM önizlemesi yapar
// (previewBand → setGain; just_audio 0.10.6'da setGain yerel değeri
// senkron günceller: _gainSubject.add, just_audio.dart:4462-4470) ve DB
// yazımı (setBandGain + saveGains) tek seferlik onChangeEnd'e
// (commitBand) taşındı. Eski kodda her tik bir updateBand başlatıyor,
// iç içe await'ler saveGains anlık görüntüsünü yarıştırıp karışık eğri
// yazabiliyordu; kalıcı yazımlar artık _enqueueWrite zincirinden geçer.
//
// Bulgu 12: toggleEnabled optimistik anahtarı hatada eski değerine
// döndürür (eski kodda kalp deseni yoktu: anahtar açık görünür ama
// EQ kapalı kalırdı) ve hatayı çağırana yansıtır.
//
// Kanıt (uydurma yok): AndroidEqualizerParameters ctor'u PUBLIC
// (just_audio.dart:4497-4501) — gerçek parametre örneği kurulur;
// AndroidEqualizerBand ctor'u PRIVATE (just_audio.dart:4439) — mocktail
// Mock implements ile sahtelenir (setGain/gain).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';

class _MockEqualizerRepository extends Mock implements EqualizerRepository {}

/// Gerçek AndroidEqualizerBand sözleşmesini yansıtır: setGain yerel
/// değeri SENKRON günceller (just_audio.dart:4462-4470 _gainSubject.add),
/// platform yazımı arka planda sürer. gain getter'ı güncel değeri okur.
class _MockBand extends Mock implements AndroidEqualizerBand {
  _MockBand(this.currentGain);
  double currentGain;
}

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

void main() {
  late _MockEqualizerRepository repo;
  late _MockPreferencesRepository prefsRepo;
  late EqualizerController ctrl;

  setUpAll(() {
    registerFallbackValue(0.0); // double bağımsız değişkenler
    registerFallbackValue(<double>[]); // saveGains listesi
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockEqualizerRepository();
    prefsRepo = _MockPreferencesRepository();
    // toggleEnabled'ın Get.find bağımlılığı; onInit _load'i tetikler.
    when(() => prefsRepo.loadPlayback())
        .thenAnswer((_) async => const PlaybackSettingsModel());
    when(() => prefsRepo.loadLibrary())
        .thenAnswer((_) async => const LibrarySettingsModel());
    Get.put<PreferencesController>(PreferencesController(prefsRepo));

    ctrl = EqualizerController(repo);
    // onInit çağrılmaz: _init ağır donanım koreografisi içerir; bu testler
    // yalnız yazım disiplini metotlarını (preview/commit/update/toggle)
    // dener ve params/isEnabled public alanlarla kurulur.
  });

  tearDown(() {
    Get.reset();
  });

  /// 3 bantlı sahte donanım: [gains] her bandın başlangıç gain'i.
  /// setGain hem KAYDEDİLİR (mocktail verify) hem de yerel değeri
  /// senkron günceller (gerçek sözleşme); gain getter'ı güncel değeri okur.
  (EqualizerController, List<_MockBand>) ctrlWithBands(
      List<double> gains) {
    final bands = List.generate(gains.length, (_) => _MockBand(0.0));
    for (var i = 0; i < bands.length; i++) {
      bands[i].currentGain = gains[i];
      when(() => bands[i].gain).thenAnswer((_) => bands[i].currentGain);
      when(() => bands[i].setGain(any())).thenAnswer((inv) async {
        bands[i].currentGain = inv.positionalArguments[0] as double;
      });
    }
    ctrl.params.value = AndroidEqualizerParameters(
      minDecibels: -15,
      maxDecibels: 15,
      bands: bands,
    );
    ctrl.isLoading.value = false;
    // Genel repo stub'ları (commit/updateBand yolları bunları çağırır;
    // gerektiğinde test içindeki daha özel stub'lar LIFO ile kazanır).
    when(() => repo.setBandGain(any(), any())).thenAnswer((_) async {});
    when(() => repo.saveGains(any())).thenAnswer((_) async {});
    return (ctrl, bands);
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('Bulgu 6: sürükleme tiki DB\u2019ye dokunmaz (previewBand)', () {
    test('setGain donanımı günceller; setBandGain/saveGains çağrılmaz',
        () async {
      final (_, bands) = ctrlWithBands([0.0, 0.0, 0.0]);

      ctrl.previewBand(0, 3.5);
      await pump();

      verify(() => bands[0].setGain(3.5)).called(1);
      verifyNever(() => repo.setBandGain(any(), any()));
      verifyNever(() => repo.saveGains(any()));
    });

    test('params dışı indeks güvenli: hiçbir şey çağrılmaz', () async {
      final (_, bands) = ctrlWithBands([0.0, 0.0, 0.0]);

      ctrl.previewBand(9, 1.0);
      await pump();

      verifyNever(() => bands[0].setGain(any()));
      verifyNever(() => repo.saveGains(any()));
    });
  });

  group('Bulgu 6: kalıcı yazım tek seferlik ve sıralı (commitBand)', () {
    test('commit: setGain + setBandGain + GÜNCEL eğri saveGains', () async {
      final (c, bands) = ctrlWithBands([1.0, 2.0, -3.0]);

      await c.commitBand(1, 2.5);

      verify(() => bands[1].setGain(2.5)).called(1);
      verify(() => repo.setBandGain(1, 2.5)).called(1);
      // Snapshot, setGain'in SENKRON güncellediği (gerçek sözleşme)
      // bant değerlerini okur: bant 1 artık 2.5.
      final captured =
          verify(() => repo.saveGains(captureAny())).captured.single
              as List<double>;
      expect(captured, [1.0, 2.5, -3.0]);
    });

    test('yazım kuyruğu: önceki yazım bitmeden sonraki başlamaz', () async {
      final (c, _) = ctrlWithBands([0.0, 0.0]);
      final gateA = Completer<void>();
      when(() => repo.setBandGain(0, any()))
          .thenAnswer((_) => gateA.future); // A kapıda bekler
      when(() => repo.setBandGain(1, any())).thenAnswer((_) async {});
      // saveGains kaydı: TAM snapshot listeleri çağrı sırasına göre.
      final snapshots = <List<double>>[];
      when(() => repo.saveGains(any())).thenAnswer((inv) async {
        snapshots.add(
          List<double>.from(inv.positionalArguments[0] as List<double>),
        );
      });

      final fa = c.commitBand(0, 11.0); // A: setBandGain(0) kapıda
      final fb = c.commitBand(1, 22.0); // B: kuyrukta bekliyor
      await pump();

      // Kilit: A'nın setBandGain'i bitmeden HİÇBİR saveGains çalışmadı.
      // (Kuyruksuzda B'nin anlık setBandGain'i önce biter, saveGains
      // A'dan önce koşardı — tam denetim raporundaki yarış.)
      expect(snapshots, isEmpty);

      gateA.complete();
      await fa;
      await fb;

      // Sıra korundu ve snapshot'lar TUTARLI: A'nın yazımı bittikten
      // sonra başlayan B, A'nın işlenmiş değerini (bant0=11) GÖRÜR;
      // karışık/bayat eğri diske yazılamaz.
      expect(snapshots, [
        [11.0, 0.0], // A: bant0=11 işlendi, bant1 henüz 0
        [11.0, 22.0], // B: A'nın değeri göründü + bant1=22 işlendi
      ]);
    });
  });

  group('Bulgu 6: preset yolu (updateBand) davranışı korundu', () {
    test('updateBand hâlâ tam yazım yapar (artık kuyruktan)', () async {
      final (c, bands) = ctrlWithBands([0.0, 0.0, 0.0]);

      await c.updateBand(0, 4.0);

      verify(() => bands[0].setGain(4.0)).called(1);
      verify(() => repo.setBandGain(0, 4.0)).called(1);
      verify(() => repo.saveGains(any())).called(1);
    });
  });

  group('Bulgu 12: toggleEnabled optimistik rollback', () {
    test('başarı: replayGain kapalıyken loudness kanalı anahtarı izler',
        () async {
      final (c, _) = ctrlWithBands([0.0]);
      when(() => repo.setEnabled(any())).thenAnswer((_) async {});
      when(() => repo.setLoudnessEnabled(any())).thenAnswer((_) async {});

      await c.toggleEnabled(true);

      expect(c.isEnabled.value, isTrue);
      verify(() => repo.setEnabled(true)).called(1);
      verify(() => repo.setLoudnessEnabled(true)).called(1);
    });

    test('başarı: replayGain açıkken loudness kanalına dokunulmaz', () async {
      final (c, _) = ctrlWithBands([0.0]);
      when(() => repo.setEnabled(any())).thenAnswer((_) async {});
      when(() => repo.setLoudnessEnabled(any())).thenAnswer((_) async {});
      Get.find<PreferencesController>().playback.value =
          const PlaybackSettingsModel(replayGain: true);

      await c.toggleEnabled(true);

      expect(c.isEnabled.value, isTrue);
      verifyNever(() => repo.setLoudnessEnabled(any()));
    });

    test('hata: anahtar eski değerine döner, önceki tercih best-effort '
        'geri yazılır, hata fırlar', () async {
      final (c, _) = ctrlWithBands([0.0]);
      c.isEnabled.value = false;
      when(() => repo.setEnabled(true)).thenThrow(Exception('platform'));
      when(() => repo.setEnabled(false)).thenAnswer((_) async {});
      when(() => repo.setLoudnessEnabled(any())).thenAnswer((_) async {});

      await expectLater(c.toggleEnabled(true), throwsA(isA<Exception>()));

      expect(c.isEnabled.value, isFalse); // rollback
      verify(() => repo.setEnabled(false)).called(1); // best-effort geri yazım
      verify(() => repo.setLoudnessEnabled(false)).called(1);
    });
  });
}
