// FAZ 2 + FAZ 3: uyku zamanlayıcısı testleri.
//
// FAZ 2: sönüm ayrı katmandır (setSleepDamping; setVolume ASLA).
// FAZ 3: sayaç mutlak deadline'dır (saat enjeksiyonuyla kanıtlanır) ve
// parça sonu olay tabanlıdır (completed + parça değişimi + repeat-one
// sarmalama gözlemi). Zamanlayıcı gerçek Timer kullanır; beklemeler
// cömert tutulur (makine yavaşlığına dayanıklı).
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';

class _MockPlayerController extends Mock implements PlayerController {
  // GetX 4.7.3 kaynağı (Kural 2): Get.put → _startController → i.onStart()
  // (get_instance.dart:254); Get.reset → onDelete(). Mock, GetLifeCycle
  // kurucusunu çalıştırmadığı için $configureLifeCycle çağrılmaz ve
  // callback alanları noSuchMethod'tan null döner → TypeError. Gerçek
  // tipler no-op callback ile somut override edilir (lifecycle.dart:7-13,
  // ValueUpdater<T> = T Function()).
  @override
  final onStart = InternalFinalCallback<void>(callback: () {});
  @override
  final onDelete = InternalFinalCallback<void>(callback: () {});

  // FAZ 3: SleepTimerController bu Rx üyelerine abone olur; mocktail
  // noSuchMethod null döndüreceği için GERÇEK Rx örnekleriyle override
  // edilir — testler .value yazarak olayları tetikler.
  @override
  final processingState = AudioProcessingState.idle.obs;
  @override
  final currentItem = Rxn<MediaItem>();
  @override
  final repeatMode = AudioServiceRepeatMode.none.obs;
  @override
  final position = Duration.zero.obs;
  @override
  final duration = Duration.zero.obs;
}

void main() {
  late _MockPlayerController player;

  setUp(() {
    player = _MockPlayerController();
    when(() => player.pause()).thenAnswer((_) async {});
    Get.put<PlayerController>(player);
  });

  tearDown(() {
    Get.reset();
  });

  // --- FAZ 2: sönüm katmanı ------------------------------------------------

  test('sönüm penceresinde tıklar setSleepDamping yazar, setVolume ASLA',
      () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());

    // 1 dk + 120 sn'lik sönüm penceresi: ilk tıkta kalan 59 sn → 59/120.
    ctrl.startTimer(1, fadeSeconds: 120);

    await Future<void>.delayed(const Duration(milliseconds: 1600));

    verify(() => player.setSleepDamping(
          any(that: closeTo(59 / 120, 0.01)),
        )).called(1);
    // K2 düzeltmesinin kanıtı: sönüm kullanıcı sesi yoluna YAZMAZ.
    verifyNever(() => player.setVolume(any()));
    verifyNever(() => player.pause());
  });

  test('süre dolunca pause + sönüm sıfırı; kullanıcı sesine dokunulmaz',
      () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());

    ctrl.startTimer(0); // kalan 0: ilk tıkta bitiş dalı

    await Future<void>.delayed(const Duration(milliseconds: 1600));

    verify(() => player.pause()).called(1);
    verify(() => player.setSleepDamping(1.0)).called(1);
    verifyNever(() => player.setVolume(any()));
    expect(ctrl.isActive.value, isFalse);
  });

  test('cancelTimer(resetVolume: true) sönümü anında sıfırlar', () {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());

    ctrl.cancelTimer(resetVolume: true);

    verify(() => player.setSleepDamping(1.0)).called(1);
    verifyNever(() => player.setVolume(any()));
  });

  test('cancelTimer(resetVolume: false) sese dokunmaz', () {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());

    ctrl.cancelTimer(resetVolume: false);

    verifyNever(() => player.setSleepDamping(any()));
    verifyNever(() => player.setVolume(any()));
  });

  // --- FAZ 3: mutlak deadline ----------------------------------------------

  test('FAZ 3: sönüm çarpanı duvar saatinden hesaplanır (tık sayımı değil)',
      () async {
    // Saat enjeksiyonu: startTimer sonrası saati 55 sn ileri alırız.
    // Mutlak deadline modeli: kalan = 60 - 55 = 5 sn → sönüm = 5/60.
    // Eski tık-sayımı kalanı 59 sanardı → sönüm 59/60 (YANLIŞ).
    var fake = DateTime(2026, 1, 1, 12, 0, 0);
    final ctrl = Get.put<SleepTimerController>(
        SleepTimerController(clock: () => fake));
    ctrl.startTimer(1, fadeSeconds: 60);

    fake = fake.add(const Duration(seconds: 55));

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    verify(() => player.setSleepDamping(
          any(that: closeTo(5 / 60, 0.01)),
        )).called(1);
    verifyNever(() => player.setSleepDamping(
          any(that: greaterThan(0.2)),
        ),); // tık-sayımı 59/60≈0.98 yazardı
  });

  test('FAZ 3: saat deadlineı geçince ilk tıkta biter (sayaç sapmaz)',
      () async {
    var fake = DateTime(2026, 1, 1, 12, 0, 0);
    final ctrl = Get.put<SleepTimerController>(
        SleepTimerController(clock: () => fake));
    ctrl.startTimer(2);

    // Saati sürenin 1 sn ötesine al: mutlak deadline geçilmiştir.
    fake = fake.add(const Duration(seconds: 121));

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // Tık-sayımı burada «kalan 119» derdi ve çalmaya devam ederdi;
    // deadline modeli ilk tıkta bitirir.
    verify(() => player.pause()).called(1);
    expect(ctrl.isActive.value, isFalse);
    expect(ctrl.remainingSeconds.value, 0);
  });

  // --- FAZ 3: parça sonu olay tabanlı ---------------------------------------

  test('FAZ 3: processingState.completed ile biter (kuyruk sonu)',
      () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());
    ctrl.startEndOfTrack();
    expect(ctrl.isEndOfTrackMode.value, isTrue);

    // Motor kuyruk sonuna geldi: audio_handler _mapProcessingState →
    // AudioProcessingState.completed.
    player.processingState.value = AudioProcessingState.completed;
    await Future<void>.delayed(Duration.zero); // handleEnd async: mikro-görev

    verify(() => player.pause()).called(1);
    expect(ctrl.isActive.value, isFalse);
    expect(ctrl.isEndOfTrackMode.value, isFalse);
  });

  test('FAZ 3: parça değişimi olayı ile biter (sırada sonraki/tekrar-tümü)',
      () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());
    player.currentItem.value =
        MediaItem(id: 'file://a.mp3', title: 'A');
    ctrl.startEndOfTrack();

    // Motor sonraki parçaya geçti: currentItem yeni kimlik taşır.
    player.currentItem.value =
        MediaItem(id: 'file://b.mp3', title: 'B');
    await Future<void>.delayed(Duration.zero); // handleEnd async

    verify(() => player.pause()).called(1);
    expect(ctrl.isEndOfTrackMode.value, isFalse);
  });

  test('FAZ 3: repeat-one başa sarma ile biter', () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());
    player.repeatMode.value = AudioServiceRepeatMode.one;
    player.duration.value = const Duration(seconds: 100);
    player.currentItem.value =
        MediaItem(id: 'file://a.mp3', title: 'A');
    ctrl.startEndOfTrack();

    // Uca yaklaş: kalan 1 sn (yalnız «yakın uç» bayrağı; ≤300 ms olmadığı
    // için henüz bitmez).
    player.position.value = const Duration(seconds: 99);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => player.pause());

    // Repeat-one: motor sessizce başa sarar (completed/currentItem GELMEZ).
    player.position.value = const Duration(milliseconds: 500);
    await Future<void>.delayed(Duration.zero); // handleEnd async

    verify(() => player.pause()).called(1);
    expect(ctrl.isEndOfTrackMode.value, isFalse);
  });

  test('FAZ 3: repeat-one elle ortaya sarma tetiklemez (kullanıcı seek\'i)',
      () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());
    player.repeatMode.value = AudioServiceRepeatMode.one;
    player.duration.value = const Duration(seconds: 100);
    ctrl.startEndOfTrack();

    player.position.value = const Duration(seconds: 99); // uç yakını
    await Future<void>.delayed(Duration.zero);
    // Kullanıcı parçanın ortasına atlar (geri sarma değil).
    player.position.value = const Duration(seconds: 50);
    await Future<void>.delayed(Duration.zero);
    // Ardından başa atlar: yakın-uç ön koşulu sıfırlandığı için tetiklenmez.
    player.position.value = const Duration(milliseconds: 500);
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => player.pause());
    expect(ctrl.isEndOfTrackMode.value, isTrue);
  });

  test('FAZ 3: cancelTimer olay aboneliklerini koparır (hijyen)', () async {
    final ctrl = Get.put<SleepTimerController>(SleepTimerController());
    ctrl.startEndOfTrack();

    ctrl.cancelTimer();

    // Abonelik koptu: completed olayı artık pause tetiklemez.
    player.processingState.value = AudioProcessingState.completed;
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => player.pause());
  });
}
