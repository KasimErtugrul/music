import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/app.dart';
import 'package:resonance/core/routes/app_routes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('Sistem dili Türkçe iken TR metin, updateLocale ile EN metin',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    // Gün 2'den itibaren varsayılan rota splash'tır (izin kontrolü yapar);
    // dil testi doğrudan ana sayfadan başlar.
    await tester.pumpWidget(const ResonanceApp(initialRoute: AppRoutes.home));
    await tester.pumpAndSettle();
    expect(find.text('Ana Sayfa'), findsWidgets);
    expect(find.text('Kütüphane'), findsWidgets);
    expect(find.text('Playlist\'ler'), findsWidgets);

    Get.updateLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
  });
}
