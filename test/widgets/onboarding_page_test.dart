// Gün 18: OnboardingPage widget testleri.
//
// Kapsam:
// - 5 sayfa sözleşmesi: 5 nokta göstergesi, karşılama başlığı, Atla + İleri
// - gezinme: İleri ilerletir, geri ok önceki sayfaya döner
// - izin adımları: medya sayfasında ana düğme «İzin ver»dir; izin verilince
//   «İleri»ye döner ve kart «İzin verildi»ye geçer (tek kaynak:
//   PermissionController)
// - bildirim adımı: gerektirmeyen cihazda (API < 33 senaryosu) ana düğme
//   doğrudan «İleri», kart bilgilendiricidir
// - özet sayfası: «Başlayalım» akışı bitirir → bayrak yazılır + yönlendirme
//   (izinler verildiyse /home)
// - Atla: akışı bitirir, izin verilmediyse /permission kapısına devreder
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/onboarding_controller.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/ui/pages/onboarding/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_permission_helper.dart';

Widget _host(Widget page) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: page,
    );

void main() {
  // Hatalı test dahi kalmış GetX kayıtlarını sonraki testlere sızdırmaz.
  tearDown(Get.reset);

  testWidgets('ilk sayfa: 5 nokta, karşılama, Atla ve İleri', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final helper = FakePermissionHelper();
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: (_) {},
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('onboarding_dot_$i')), findsOneWidget,
          reason: 'nokta $i eksik');
    }
    expect(find.text("Resonance'a hoş geldiniz"), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('İleri gezinir; geri ok önceki sayfaya döner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final helper = FakePermissionHelper();
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: (_) {},
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    // Özellikler sayfası
    await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
    await tester.pumpAndSettle();
    expect(find.text('Sizi bekleyenler'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Geri ok karşılama sayfasına döner
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text("Resonance'a hoş geldiniz"), findsOneWidget);
  });

  testWidgets('medya adımı: «İzin ver» verir, kart ve ana düğme döner',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final helper = FakePermissionHelper();
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: (_) {},
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    // 2 kez İleri → medya sayfası (sayfa 3)
    await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
    await tester.pumpAndSettle();

    expect(find.text('Müzik dosyalarınıza erişim'), findsOneWidget);
    // İzin verilmedi: ana düğme «İzin ver», kartta da «İzin ver» düğmesi.
    expect(find.text('İzin ver'), findsNWidgets(2));
    expect(find.text('Müzik ve ses dosyaları'), findsOneWidget);

    helper.media = AppPermissionStatus.granted;
    await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
    await tester.pumpAndSettle();

    expect(helper.requestMediaCalls, 1);
    expect(find.text('İzin verildi'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
  });

  testWidgets('bildirim adımı: gerekmeyen cihazda bilgilendirici, «İleri»',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Medya verilmiş: 3. sayfanın ana düğmesi «İleri» kalır, akış 4. sayfaya
    // ulaşır. Bildirim gereksinimi kapalı (API < 33 senaryosu).
    final helper = FakePermissionHelper(
      media: AppPermissionStatus.granted,
      notificationRequired: false,
    );
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: (_) {},
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bu cihazda bildirim için ayrıca izin gerekmez.'),
        findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
    expect(helper.requestNotificationCalls, 0);
  });

  testWidgets('özet + Başlayalım: bayrak yazılır, /home yollar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final helper = FakePermissionHelper(
      media: AppPermissionStatus.granted,
      notification: AppPermissionStatus.granted,
    );
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();

    final routes = <String>[];
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: routes.add,
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    // Son sayfaya kadar ilerle (izinler zaten verili: düğme hep «İleri»).
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Her şey hazır!'), findsOneWidget);
    expect(find.text('Başlayalım'), findsOneWidget);
    expect(find.text('İzin verildi'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('onboarding_primary')));
    await tester.pumpAndSettle();

    expect(routes, [AppRoutes.home]);
    expect(prefs.getBool('onboarding.completed'), isTrue);
  });

  testWidgets('Atla: izin verilmediyse /permission kapısına devreder',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final helper = FakePermissionHelper();
    final pc = PermissionController(helper);
    Get.put<PermissionController>(pc);
    await pc.refresh();

    final routes = <String>[];
    Get.put<OnboardingController>(OnboardingController(
      prefs: prefs,
      permission: pc,
      navigate: routes.add,
    ));

    await tester.pumpWidget(_host(const OnboardingPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(routes, [AppRoutes.permission]);
    expect(prefs.getBool('onboarding.completed'), isTrue);
  });
}
