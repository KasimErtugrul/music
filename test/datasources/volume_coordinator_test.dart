// FAZ 2: ses tek sahipliği — VolumeCoordinator birim testleri.
//
// Katman modeli: efektif ses = kullanıcı sesi × rampa × duck × uyku sönümü.
// Testler katman bağımsızlığını, çarpım matematiğini ve tek-yazım
// sözleşmesini doğrular.
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/volume_coordinator.dart';

void main() {
  late List<double> written;
  late VolumeCoordinator volume;

  setUp(() {
    written = <double>[];
    volume = VolumeCoordinator(
      writeVolume: (v) async => written.add(v),
    );
  });

  test('başlangıçta tüm katmanlar 1.0; ilk yazım yapılmaz', () {
    expect(volume.effective, 1.0);
    expect(volume.userVolume, 1.0);
    expect(volume.rampFactor, 1.0);
    expect(written, isEmpty);
  });

  test('efektif ses katmanların çarpımıdır', () async {
    await volume.setUserVolume(0.5);
    await volume.setDuckFactor(0.3);
    await volume.setSleepDamping(0.4);
    // rampa 1.0: 0.5 × 1 × 0.3 × 0.4 = 0.06
    expect(volume.effective, closeTo(0.06, 1e-12));
    expect(written.last, closeTo(0.06, 1e-12));
  });

  test('her katman değişimi tam çarpımı TEK yazımla bildirir', () async {
    await volume.setUserVolume(0.8);
    expect(written.length, 1);
    await volume.setSleepDamping(0.5);
    expect(written.length, 2);
    expect(written.last, closeTo(0.4, 1e-12));
    await volume.setRampFactor(0.5);
    expect(written.length, 3);
    expect(written.last, closeTo(0.2, 1e-12));
  });

  test('katmanlar bağımsızdır: uyku sönümü kullanıcı sesini ezmez', () async {
    await volume.setUserVolume(0.4);
    await volume.setSleepDamping(0.9);
    expect(volume.userVolume, 0.4); // kullanıcının tercihi korunur
    expect(volume.effective, closeTo(0.36, 1e-12));
    await volume.setSleepDamping(1.0); // sönüm biter
    expect(volume.effective, closeTo(0.4, 1e-12)); // tercih geri gelir
  });

  test('aralık dışı değerler 0–1 aralığına kelepçelenir', () async {
    await volume.setUserVolume(-0.5);
    expect(volume.userVolume, 0.0);
    await volume.setUserVolume(2.0);
    expect(volume.userVolume, 1.0);
    await volume.setDuckFactor(7);
    await volume.setSleepDamping(-1);
    await volume.setRampFactor(42);
    expect(volume.effective, isIn([0.0, closeTo(0.0, 1e-12)]));
  });

  test('userTakesOver rampa çarpanını bitirir ve TEK yazım yapar', () async {
    await volume.setRampFactor(0.3); // fade-in ortası
    written.clear();

    await volume.userTakesOver(0.8);

    expect(volume.userVolume, 0.8);
    expect(volume.rampFactor, 1.0);
    expect(written.length, 1);
    expect(written.single, closeTo(0.8, 1e-12));
  });

  test('endRamp çarpanı 1e sabitleyip efektifi geri yazar', () async {
    await volume.setUserVolume(0.6);
    await volume.setRampFactor(0.1);
    written.clear();

    await volume.endRamp();

    expect(volume.rampFactor, 1.0);
    expect(written.single, closeTo(0.6, 1e-12));
  });
}
