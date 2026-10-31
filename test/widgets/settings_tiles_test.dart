import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_tile.dart';

/// Gün 12: birleşik ayar döşemesi davranışları.
///
/// Kapsam: DropdownButton'ın kaldırılması (≤3 → SegmentedButton, >3 →
/// alt sayfa listesi), 48 dp dokunma hedefi, Semantics etiketleri,
/// altyazı gösterimi ve SettingsGroupCard/SettingsTile çizimi.
void main() {
  Widget sarmala(Widget child) => MaterialApp(
        home: Scaffold(body: ListView(children: [child])),
      );

  testWidgets('≤3 seçenek: SegmentedButton çizilir, DropdownButton yok',
      (tester) async {
    await tester.pumpWidget(sarmala(SettingsChoiceTile<String>(
      title: 'Mod',
      value: 'a',
      options: const ['a', 'b', 'c'],
      labelOf: (v) => v.toUpperCase(),
      onChanged: (_) {},
    )));
    await tester.pump();

    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);
    // Tüm seçenek etiketleri görünür.
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('≤3 seçenek: segment dokunma hedefi en az 48 dp',
      (tester) async {
    await tester.pumpWidget(sarmala(SettingsChoiceTile<int>(
      title: 'Tekrar',
      value: 1,
      options: const [0, 1, 2],
      labelOf: (v) => '$v',
      onChanged: (_) {},
    )));
    await tester.pump();

    final rect = tester.getRect(find.byType(SegmentedButton<int>));
    expect(rect.height, greaterThanOrEqualTo(48));
  });

  testWidgets('≤3 seçenek: segment seçimi onChanged çağrısını tetikler',
      (tester) async {
    int? secilen;
    await tester.pumpWidget(sarmala(SettingsChoiceTile<int>(
      title: 'Tekrar',
      value: 1,
      options: const [0, 1, 2],
      labelOf: (v) => '$v',
      onChanged: (v) => secilen = v,
    )));
    await tester.pump();

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(secilen, 2);
  });

  testWidgets('>3 seçenek: alt sayfa açılır, seçim onChanged + kapanır',
      (tester) async {
    int? secilen;
    await tester.pumpWidget(sarmala(SettingsChoiceTile<int>(
      title: 'Sarma',
      subtitle: 'Sarma süresi',
      value: 10,
      options: const [5, 10, 15, 30],
      labelOf: (v) => '$v sn',
      onChanged: (v) => secilen = v,
    )));
    await tester.pump();

    // DropdownButton yok; satır geçerli değeri gösteriyor.
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('10 sn'), findsOneWidget);

    await tester.tap(find.text('Sarma'));
    await tester.pumpAndSettle();

    // Alt sayfada tüm seçenekler listelenir.
    expect(find.text('30 sn'), findsOneWidget);
    await tester.tap(find.text('30 sn'));
    await tester.pumpAndSettle();

    expect(secilen, 30);
    // Sayfa kapandı. StatelessWidget harici bir değişkene yazdığı için
    // kendi kendine yeniden çizilmez; gerçek uygulamada controller yeniden
    // pompalar. Yeni değere sahip örnek pompanınca satır yeni değeri
    // gösterir.
    await tester.pumpWidget(sarmala(SettingsChoiceTile<int>(
      title: 'Sarma',
      subtitle: 'Sarma süresi',
      value: secilen!,
      options: const [5, 10, 15, 30],
      labelOf: (v) => '$v sn',
      onChanged: (v) => secilen = v,
    )));
    await tester.pump();
    expect(find.text('30 sn'), findsOneWidget);
    expect(find.text('Sarma'), findsOneWidget);
  });

  testWidgets('>3 seçenek: Semantics satırı başlık + geçerli değerle okur',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(sarmala(SettingsChoiceTile<int>(
      title: 'Sarma',
      subtitle: 'Sarma süresi',
      value: 10,
      options: const [5, 10, 15, 30],
      labelOf: (v) => '$v sn',
      onChanged: (_) {},
    )));
    await tester.pump();

    final node = tester.getSemantics(find.text('Sarma'));
    expect(node.label, 'Sarma. Sarma süresi');
    expect(node.value, '10 sn');
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('SettingsGroupCard çocukları çizer, SettingsTile altyazılı okur',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(sarmala(SettingsGroupCard(children: [
      const SettingsTile(
        title: 'Ekolayzır',
        subtitle: 'Ekolayzır ve ses efektleri',
        onTap: null,
      ),
    ])));
    await tester.pump();

    expect(find.text('Ekolayzır'), findsOneWidget);
    expect(find.text('Ekolayzır ve ses efektleri'), findsOneWidget);
    final node = tester.getSemantics(find.text('Ekolayzır'));
    expect(node.label, 'Ekolayzır. Ekolayzır ve ses efektleri');
    handle.dispose();
  });
}
