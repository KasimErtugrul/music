// Gün 18: OnboardingController birim testleri.
//
// Kapsam:
// - shouldShow: bayrak yoksa doğru, complete() sonrası yanlış (kalıcı)
// - start(): bayrak yazılıysa akışı AÇMAZ (ikinci açılış sözleşmesi)
// - complete(): bayrağı yazar; medya verildiyse /home, verilmediyse mevcut
//   /permission kapısına devreder (izin atlanamaz)
// - skip(): complete() ile aynı sözleşme
// - currentPage/isLast: sayfa durumu PageView'dan beslenir
// - isMediaGranted/isNotificationGranted: PermissionController aynası
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/presentation/controllers/onboarding_controller.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_permission_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  Future<(OnboardingController, PermissionController, FakePermissionHelper,
          List<String>)>
      build({
    AppPermissionStatus media = AppPermissionStatus.denied,
    AppPermissionStatus notification = AppPermissionStatus.denied,
    bool notificationRequired = true,
    Map<String, Object> prefsSeed = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsSeed);
    final prefs = await SharedPreferences.getInstance();

    final helper = FakePermissionHelper(
      media: media,
      notification: notification,
      notificationRequired: notificationRequired,
    );
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh(); // onInit'teki refresh'i deterministik bekleriz

    final routes = <String>[];
    final controller = OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: routes.add,
      pageController: PageController(),
    );
    Get.put<OnboardingController>(controller);
    return (controller, pc, helper, routes);
  }

  test('bayrak yoksa shouldShow doğrudur; complete sonrası kalıcı yanlış',
      () async {
    final (c, _, _, routes) = await build();
    expect(c.shouldShow, isTrue);

    await c.complete();
    expect(c.shouldShow, isFalse);
    expect(c.completed.value, isTrue);
    // Medya izni verilmediği için mevcut izin kapısına devreder.
    expect(routes, [AppRoutes.permission]);
  });

  test('bayrak yazılıyken start() akışı açmaz', () async {
    final (c, _, _, routes) = await build(prefsSeed: {
      'onboarding.completed': true,
    });
    expect(c.shouldShow, isFalse);
    c.start();
    expect(routes, isEmpty);
  });

  test('bayrak yokken start() onboarding sayfasını açar', () async {
    final (c, _, _, routes) = await build();
    c.start();
    expect(routes, [AppRoutes.onboarding]);
  });

  test('medya izni verildiyse complete() doğrudan /home yollar', () async {
    final (c, _, _, routes) = await build(
      media: AppPermissionStatus.granted,
      notification: AppPermissionStatus.denied,
    );
    await c.complete();
    expect(routes, [AppRoutes.home]);
  });

  test('skip() de akışı bitirir: bayrak + izin kapısı devri', () async {
    final (c, _, _, routes) = await build();
    await c.skip();
    expect(c.shouldShow, isFalse);
    expect(routes, [AppRoutes.permission]);
  });

  test('complete() çift çağrı ikinci yönlendirmeyi yapmaz', () async {
    final (c, _, _, routes) = await build(
      media: AppPermissionStatus.granted,
    );
    await c.complete();
    await c.complete();
    expect(routes, [AppRoutes.home]);
  });

  test('sayfa durumu: onPageChanged besler, isLast yalnız 5. sayfada',
      () async {
    final (c, _, _, _) = await build();
    expect(c.isLast, isFalse);
    c.onPageChanged(2);
    expect(c.currentPage.value, 2);
    expect(c.isLast, isFalse);
    c.onPageChanged(4);
    expect(c.currentPage.value, 4);
    expect(c.isLast, isTrue);
  });

  test('izin aynası: denetleyici durumu birebir yansır', () async {
    final (c, pc, helper, _) = await build(
      media: AppPermissionStatus.permanentlyDenied,
      notification: AppPermissionStatus.granted,
      notificationRequired: false,
    );
    expect(c.isMediaGranted, isFalse);
    expect(c.isNotificationGranted, isTrue);
    expect(c.notificationRequired, isFalse);

    // Durum değişimi: kasa senaryosu — kullanıcı ayarlardan izin verip
    // döner; PermissionController.refresh (lifecycle) tetiklenir.
    helper.media = AppPermissionStatus.granted;
    await pc.refresh();
    expect(c.isMediaGranted, isTrue);
  });
}
