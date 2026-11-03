import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/resonance_app_bar.dart';

/// ResonanceAppBar — alt gezinmedeki beş sekmenin ortak marka üst bandı.
///
/// Kilit garantiler:
/// 1. Marka başlığı («Resonance» + graphic_eq ikonu) daima çizilir; l10n
///    değişse bile metin uygulama adıdır (TR/EN ikisi de «Resonance»).
/// 2. preferredSize: kToolbarHeight + alt bölge yüksekliği — Kitaplık'ın
///    sekme hapı bölgesi Scaffold tarafından doğru yer tutulur.
/// 3. actions ileriye dönük olarak çizilir (Kitaplık eylem düğmeleri).
void main() {
  Widget pumpHost({ResonanceAppBar? appBar}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(
        appBar: appBar ?? ResonanceAppBar(),
        body: const SizedBox.expand(),
      ),
    );
  }

  testWidgets('marka başlığı: «Resonance» + graphic_eq ikonu çizilir', (
    tester,
  ) async {
    await tester.pumpWidget(pumpHost());
    await tester.pumpAndSettle();

    expect(find.text('Resonance'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    // Sekme adları artık AppBar'da değildir:
    expect(find.text('Kütüphane'), findsNothing);
    expect(find.text('Ayarlar'), findsNothing);
  });

  testWidgets('EN yerelinde de aynı marka metni çizilir', (tester) async {
    await tester.pumpWidget(pumpHost());
    await tester.pumpAndSettle();

    // MaterialApp yerelini EN'e çevir:
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          appBar: ResonanceAppBar(),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resonance'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
  });

  testWidgets('preferredSize: sade iken kToolbarHeight; bottom eklenince '
      'yüksekliği toplanır', (tester) async {
    final plain = ResonanceAppBar();
    expect(plain.preferredSize.height, kToolbarHeight);

    const bottom = PreferredSize(
      preferredSize: Size.fromHeight(46),
      child: SizedBox.shrink(),
    );
    final withBottom = ResonanceAppBar(bottom: bottom);
    expect(withBottom.preferredSize.height, kToolbarHeight + 46);
  });

  testWidgets('actions bölgesi çizilir (Kitaplık eylem düğmeleri senaryosu)', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpHost(
        appBar: ResonanceAppBar(
          actions: [Icon(Icons.sync, key: ValueKey('sync-action'))],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sync-action')), findsOneWidget);
    // Eylemler varken de marka başlığı tek ve yerinde:
    expect(find.text('Resonance'), findsOneWidget);
  });

  testWidgets('bottom bölgesi AppBar altında çizilir', (tester) async {
    // DİKKAT: flex çocuğu olan AppBar Column'unda flex olmayan bottom
    // çocuğu KISITSIZ ana eksende ölçülür — bu yüzden çocuksuz
    // `Container(color:)` 0 yüksekliğe düşer (gerçek sayfalardaki gibi
    // sabit yükseklikli içerik doğru ölçülür). Fixture sabit 46dp.
    await tester.pumpWidget(
      pumpHost(
        appBar: ResonanceAppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: SizedBox(
              height: 46,
              child: Container(
                key: const ValueKey('pills-region'),
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBarTop = tester.getTopLeft(find.byType(AppBar)).dy;
    final pillsRect = tester.getRect(
      find.byKey(const ValueKey('pills-region')),
    );
    // Alt bölge araç çubuğunun (56dp) hemen altında ve tam 46dp:
    expect(pillsRect.top, greaterThan(appBarTop));
    expect(pillsRect.top, closeTo(appBarTop + kToolbarHeight, 0.5));
    expect(pillsRect.height, closeTo(46, 0.5));
  });
}
