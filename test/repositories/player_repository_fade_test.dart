// Gün 20: yumuşatma (fade) birim testleri.
//
// PlayerRepositoryImpl artık play/pause çağrılarında sesi kademeli taşır.
// Rampalar GERÇEK zamanlayıcılarla çalışır (Timer.periodic); testler
// beklemeleri cömert tutup yalnız SON durumları doğrular — ara tık
// sayısını saymaz, böylece makine yavaşlığına dayanıklıdır.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/repositories/player_repository.dart';

class _MockHandler extends Mock implements ResonanceAudioHandler {}

void main() {
  late _MockHandler handler;
  late PlayerRepositoryImpl repo;
  late List<double> volumes;

  setUp(() {
    handler = _MockHandler();
    repo = PlayerRepositoryImpl(handler);
    volumes = <double>[];
    when(() => handler.play()).thenAnswer((_) async {});
    when(() => handler.pause()).thenAnswer((_) async {});
    when(() => handler.stop()).thenAnswer((_) async {});
    when(() => handler.setVolume(any())).thenAnswer((inv) async {
      volumes.add(inv.positionalArguments[0] as double);
    });
  });

  test('fade kapalıyken play/pause sese dokunmaz ve anlık duraklatır', () async {
    repo.setFadeDuration(Duration.zero);

    await repo.play();
    await repo.pause();

    expect(volumes, isEmpty);
    verify(() => handler.pause()).called(1);
    verify(() => handler.play()).called(1);
  });

  test('fade kısa: play sesi 0dan hedefe taşır, pause 0a indirip duraklatır',
      () async {
    repo.setFadeDuration(const Duration(milliseconds: 250));

    await repo.play();
    // İlk yazım (0.0) play dönerken senkron gerçekleşmiş olmalı.
    expect(volumes, [0.0]);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(volumes.last, 1.0); // hedef ses: varsayılan 1.0
    for (var i = 1; i < volumes.length; i++) {
      expect(volumes[i], greaterThanOrEqualTo(volumes[i - 1]),
          reason: 'fade-in monoton artmalı: $volumes');
    }

    volumes.clear();
    await repo.pause();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(volumes.last, 0.0);
    verify(() => handler.pause()).called(1);
  });

  test('fade-out ortasında kullanıcı sesi değiştirirse duraklatma iptal olur',
      () async {
    repo.setFadeDuration(const Duration(milliseconds: 1000));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    volumes.clear();

    await repo.pause();
    // Fade-out ilk tıkları yazdıktan sonra kullanıcı müdahale eder.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.setVolume(0.8);
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(volumes.last, 0.8);
    verifyNever(() => handler.pause());
  });

  test('fade-out ortasında play gelirse beklemedeki pause atlanır', () async {
    repo.setFadeDuration(const Duration(milliseconds: 1000));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    volumes.clear();

    await repo.pause();
    await repo.play(); // fade-out henüz bitmedi: jenerasyon iptal olur
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    verifyNever(() => handler.pause());
    expect(volumes.last, 1.0); // fade-in yeniden hedefe tamamlandı
  });

  test('stop aktif rampayı iptal eder', () async {
    repo.setFadeDuration(const Duration(milliseconds: 250));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await repo.stop();
    final countAtStop = volumes.length;
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(volumes.length, countAtStop); // rampa yazmayı bıraktı
    verify(() => handler.stop()).called(1);
  });
}