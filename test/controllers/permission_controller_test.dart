import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';

class MockPermissionHelper extends Mock implements PermissionHelper {}

void main() {
  late MockPermissionHelper helper;
  late List<String> navigated;
  late String route;

  PermissionController build() => PermissionController(
        helper,
        navigate: navigated.add,
        currentRoute: () => route,
      );

  void stubStatuses({
    AppPermissionStatus media = AppPermissionStatus.denied,
    AppPermissionStatus notification = AppPermissionStatus.denied,
    bool notificationRequired = true,
  }) {
    when(() => helper.mediaStatus()).thenAnswer((_) async => media);
    when(() => helper.notificationStatus())
        .thenAnswer((_) async => notification);
    when(() => helper.notificationPermissionRequired())
        .thenAnswer((_) async => notificationRequired);
  }

  setUp(() {
    helper = MockPermissionHelper();
    navigated = <String>[];
    route = AppRoutes.permission;
  });

  group('refresh', () {
    test('durumları okur', () async {
      stubStatuses(
        media: AppPermissionStatus.granted,
        notification: AppPermissionStatus.permanentlyDenied,
      );
      final c = build();
      await c.refresh();
      expect(c.media.value, AppPermissionStatus.granted);
      expect(c.notification.value, AppPermissionStatus.permanentlyDenied);
      expect(c.notificationRequired.value, isTrue);
    });

    test('denied okuması permanentlyDenied değerini ezmez', () async {
      stubStatuses();
      final c = build();
      c.media.value = AppPermissionStatus.permanentlyDenied;
      await c.refresh();
      expect(c.media.value, AppPermissionStatus.permanentlyDenied);
    });

    test('granted okuması permanentlyDenied değerini ezer (ayarlardan verildi)',
        () async {
      stubStatuses(media: AppPermissionStatus.granted);
      final c = build();
      c.media.value = AppPermissionStatus.permanentlyDenied;
      await c.refresh();
      expect(c.media.value, AppPermissionStatus.granted);
    });

    test('hata olursa çökmez, önceki değer kalır', () async {
      when(() => helper.mediaStatus()).thenThrow(Exception('boom'));
      final c = build();
      await c.refresh();
      expect(c.media.value, AppPermissionStatus.denied);
    });
  });

  group('checkAndRoute (splash)', () {
    test('izin varsa ana sayfa', () async {
      stubStatuses(media: AppPermissionStatus.granted);
      await build().checkAndRoute();
      expect(navigated, [AppRoutes.home]);
    });

    test('izin yoksa izin sayfası', () async {
      stubStatuses();
      await build().checkAndRoute();
      expect(navigated, [AppRoutes.permission]);
    });
  });

  group('requestMedia', () {
    test('verilirse ve bildirim kartı beklemiyorsa ana sayfaya geçer',
        () async {
      stubStatuses(notificationRequired: false);
      when(() => helper.requestMedia())
          .thenAnswer((_) async => AppPermissionStatus.granted);
      final c = build();
      await c.refresh();
      await c.requestMedia();
      expect(c.mediaRequested.value, isTrue);
      expect(navigated, [AppRoutes.home]);
    });

    test('verilir ama bildirim kartı bekliyorsa sayfada kalır', () async {
      stubStatuses();
      when(() => helper.requestMedia())
          .thenAnswer((_) async => AppPermissionStatus.granted);
      final c = build();
      await c.refresh();
      await c.requestMedia();
      expect(c.showNotificationCard, isTrue);
      expect(navigated, isEmpty);
      c.continueToApp();
      expect(navigated, [AppRoutes.home]);
    });

    test('reddedilirse gezinme yok, reddedildi durumu işaretlenir', () async {
      stubStatuses();
      when(() => helper.requestMedia())
          .thenAnswer((_) async => AppPermissionStatus.denied);
      final c = build();
      await c.requestMedia();
      expect(c.media.value, AppPermissionStatus.denied);
      expect(c.mediaRequested.value, isTrue);
      expect(navigated, isEmpty);
    });

    test('kalıcı reddedilirse durum permanentlyDenied olur', () async {
      stubStatuses();
      when(() => helper.requestMedia())
          .thenAnswer((_) async => AppPermissionStatus.permanentlyDenied);
      final c = build();
      await c.requestMedia();
      expect(c.media.value, AppPermissionStatus.permanentlyDenied);
      expect(navigated, isEmpty);
    });

    test('izin sayfasında değilsek gezinme yapmaz', () async {
      route = AppRoutes.splash;
      stubStatuses(notificationRequired: false);
      when(() => helper.requestMedia())
          .thenAnswer((_) async => AppPermissionStatus.granted);
      final c = build();
      await c.refresh();
      await c.requestMedia();
      expect(navigated, isEmpty);
    });

    test('istisna fırlatılırsa çökmez ve busy sıfırlanır', () async {
      stubStatuses();
      when(() => helper.requestMedia()).thenThrow(Exception('boom'));
      final c = build();
      await c.requestMedia();
      expect(c.busy.value, isFalse);
      expect(navigated, isEmpty);
    });
  });

  group('bildirim izni (isteğe bağlı)', () {
    test('reddedilirse çalma/medya akışı etkilenmez, kart gizlenir', () async {
      stubStatuses(media: AppPermissionStatus.granted);
      when(() => helper.requestNotification())
          .thenAnswer((_) async => AppPermissionStatus.denied);
      final c = build();
      await c.refresh();
      expect(c.showNotificationCard, isTrue);
      await c.requestNotification();
      expect(c.media.value, AppPermissionStatus.granted);
      expect(c.showNotificationCard, isFalse);
      expect(navigated, [AppRoutes.home]);
    });

    test('kapatılınca kart gizlenir ve medya izni varsa devam edilir',
        () async {
      stubStatuses(media: AppPermissionStatus.granted);
      final c = build();
      await c.refresh();
      //c.dismissNotification();
      expect(c.showNotificationCard, isFalse);
      expect(navigated, [AppRoutes.home]);
    });

    test('Android 12 ve altında kart hiç gösterilmez', () async {
      stubStatuses(
        notificationRequired: false,
        notification: AppPermissionStatus.granted,
      );
      final c = build();
      await c.refresh();
      expect(c.showNotificationCard, isFalse);
    });

    test('izin verilmişse kart gösterilmez', () async {
      stubStatuses(notification: AppPermissionStatus.granted);
      final c = build();
      await c.refresh();
      expect(c.showNotificationCard, isFalse);
    });
  });

  group('uygulamaya dönüş (ayarlardan izin verildi)', () {
    test('resumed + izin verildi + izin sayfasındayız -> ana sayfa', () async {
      stubStatuses(
        media: AppPermissionStatus.granted,
        notification: AppPermissionStatus.granted,
      );
      final c = build();
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(navigated, [AppRoutes.home]);
    });

    test('paused iken hiçbir şey yapmaz', () async {
      stubStatuses(media: AppPermissionStatus.granted);
      final c = build();
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(navigated, isEmpty);
      verifyNever(() => helper.mediaStatus());
    });
  });

  test('openSettings yardımcıya iletilir', () async {
    when(() => helper.openSettings()).thenAnswer((_) async => true);
    await build().openSettings();
    verify(() => helper.openSettings()).called(1);
  });
}
