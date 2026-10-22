import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';

void main() {
  testWidgets('Sistem dili Türkçe iken TR metin, updateLocale ile EN metin',
      (tester) async {
    // NOT: Bu test `ResonanceApp`'i pump ETMEZ — çünkü `InitialBinding`
    // `ResonanceAudioHandler`'a bağımlı, test ortamında kayıtlı değil.
    // Bu testin kapsamı yalnızca lokalizasyon: TR metin → EN metin.
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: Column(
                children: <Widget>[
                  Text(l10n.tabHome),
                  Text(l10n.tabLibrary),
                  Text(l10n.tabSearch),
                ],
              ),
            );
          },
        ),
      ),
    );

    // TR
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Kütüphane'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);

    // TR → EN
    Get.updateLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}