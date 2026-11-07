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

    // FAZ 2: pause() rampa bitince döner; beklemeden kullanıcı müdahalesi
    // yapıp Future'ın yine de tamamlandığını doğrularız (asılı await yok).
    final pausing = repo.pause();
    // Fade-out ilk tıkları yazdıktan sonra kullanıcı müdahale eder.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.setVolume(0.8); // rampayı devralır: gecikmeli pause düşer
    await pausing;
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(volumes.last, 0.8);
    verifyNever(() => handler.pause());
  });

  test('fade-out ortasında play gelirse beklemedeki pause atlanır', () async {
    repo.setFadeDuration(const Duration(milliseconds: 1000));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    volumes.clear();

    final pausing = repo.pause();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.play(); // fade-out henüz bitmedi: jenerasyon iptal olur
    await pausing; // iptal edilen rampa Future'ı yine tamamlanır
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

  // --- FAZ 2: katman modeli + rampa-bitince-Future sözleşmesi -------------

  test('FAZ 2: pause Future rampa BİTİNCE döner (rampa sürerken değil)',
      () async {
    repo.setFadeDuration(const Duration(milliseconds: 250));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    volumes.clear();

    var pauseReturned = false;
    final pausing = repo.pause().then((_) => pauseReturned = true);

    // Rampa hâlâ iniyor: Future tamamlanmadı, son değer henüz 0 değil.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(pauseReturned, isFalse,
        reason: 'pause, fade-out sürerken dönmemeli (FAZ 2 sözleşmesi)');
    expect(volumes.last, greaterThan(0.0));

    await pausing;
    expect(pauseReturned, isTrue);
    expect(volumes.last, 0.0); // fade-out tamamlandı
    verify(() => handler.pause()).called(1); // pause rampadan SONRA yapıldı
  });

  test('FAZ 2: uyku sönümü katmandır — kullanıcı sesiyle çarpılır, rampayı '
      'iptal etmez', () async {
    repo.setFadeDuration(const Duration(milliseconds: 250));

    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    volumes.clear();

    // Sönüm tek başına: efektif = kullanıcı(1.0) × rampa(1.0) × sönüm(0.5)
    repo.setSleepDamping(0.5);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(volumes, hasLength(1));
    expect(volumes.first, closeTo(0.5, 1e-9));

    // Pause rampası sönüm SÜRERKEN başlar: iptal OLMAZ, rampa bitip
    // duraklatır; ara yazımlar çarpım (rampa × 0.5) ile iner.
    final pausing = repo.pause();
    await pausing; // FAZ 2: rampa bitince döner
    expect(volumes.last, 0.0);
    verify(() => handler.pause()).called(1);

    // Sönüm biter: duraklatılmışta rampa çarpanı 0.0 olduğundan efektif
    // 0 kalır (sessiz — doğru), ama kullanıcı tercihi KORUNMUŞTUR.
    repo.setSleepDamping(1.0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(volumes.last, 0.0);

    // Kullanıcı sesi değişirse rampayı devralır: tercih ezilmemiştir.
    await repo.setVolume(0.7);
    expect(volumes.last, closeTo(0.7, 1e-9));

    // Sonraki fade-in kullanıcının sesine kadar iner (1.0'a değil).
    await repo.play();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(volumes.last, closeTo(0.7, 1e-9));
  });

  test('FAZ 2: fadeMs=0 ile uyku sönümü davranışı birebir (anlık)', () async {
    repo.setFadeDuration(Duration.zero);

    await repo.play();
    repo.setSleepDamping(0.4);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Rampa yok: sönüm tek yazımla uygulanır, pause anlıktır.
    await repo.pause();
    verify(() => handler.pause()).called(1);
    repo.setSleepDamping(1.0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Duraklatılmışta efektif = kullanıcı(1.0) × rampa(1.0) × sönüm(1.0)
    expect(volumes.last, 1.0);
    // play() yalnız baştaki 1 çağrı: sönüm/katman yazımları play tetiklemez.
    verify(() => handler.play()).called(1);
  });
}