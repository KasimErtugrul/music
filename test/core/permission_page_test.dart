import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/ui/pages/permission_page.dart';

class MockPermissionHelper extends Mock implements PermissionHelper {}

void main() {
  late PermissionController controller;

  setUp(() {
    controller = PermissionController(
      MockPermissionHelper(),
      navigate: (_) {},
      currentRoute: () => '',
    );
    Get.put<PermissionController>(controller);
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      GetMaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PermissionPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ilk durum: izin ver düğmesi görünür (TR)', (tester) async {
    await pumpPage(tester, const Locale('tr'));
    expect(find.text('Müzik ve ses dosyaları'), findsOneWidget);
    expect(find.text('İzin ver'), findsOneWidget);
    expect(find.text('Uygulama ayarlarına git'), findsNothing);
  });

  testWidgets('kalıcı reddedildi: ayarlara git düğmesi görünür (TR)',
      (tester) async {
    controller.media.value = AppPermissionStatus.permanentlyDenied;
    await pumpPage(tester, const Locale('tr'));
    expect(find.text('İzin kalıcı olarak reddedildi'), findsOneWidget);
    expect(find.text('Uygulama ayarlarına git'), findsOneWidget);
    expect(find.text('İzin ver'), findsNothing);
  });

  testWidgets('reddedildi (kalıcı değil): tekrar dene mesajı (EN)',
      (tester) async {
    controller.mediaRequested.value = true;
    await pumpPage(tester, const Locale('en'));
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
  });

  testWidgets('bildirim kartı yalnızca gerektiğinde görünür', (tester) async {
    controller.notificationRequired.value = true;
    await pumpPage(tester, const Locale('tr'));
    expect(find.text('Bildirim izni'), findsOneWidget);

    controller.notificationRequired.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Bildirim izni'), findsNothing);
  });
}
