// Gün 12: ortak ayar bileşenlerinin tasarım sözleşmesi testleri.
//
// Kapsam:
// - SettingsChoiceTile ≤3 seçenek → SegmentedButton (48 dp hedef, Semantics
//   grup etiketi, DropdownButton yok)
// - SettingsChoiceTile >3 seçenek → alt sayfa radyo listesi (RadioGroup +
//   RadioListTile, 48 dp+ satır, seçim pop + değer bildirimi)
// - SettingsSwitchTile alt açıklama gösterir ve değeri bildirir
// - SettingsGroupCard başlık + çocukları kart yüzeyinde çizer
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3 seçenek: SegmentedButton çizilir; 48 dp hedef ve '
      'Semantics etiketi var; seçim değeri bildirilir', (tester) async {
    final semantics = tester.ensureSemantics();
    String? selected;
    await tester.pumpWidget(_host(
      SettingsChoiceTile<String>(
        title: 'Mod',
        subtitle: 'açıklama',
        value: 'b',
        options: const ['a', 'b', 'c'],
        labelOf: (v) => v.toUpperCase(),
        onChanged: (v) => selected = v,
      ),
    ));

    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    // Gün 12: DropdownButton kaldırıldı.
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('açıklama'), findsOneWidget);

    // Dokunma hedefi: segment satırı >= 48 dp.
    expect(
      tester.getSize(find.byType(SegmentedButton<String>)).height,
      greaterThanOrEqualTo(48),
    );
    // Semantics: grup, ayar adını etiket olarak taşır.
    expect(find.bySemanticsLabel('Mod'), findsWidgets);

    await tester.tap(find.text('C'));
    await tester.pump();
    expect(selected, 'c');
    semantics.dispose();
  });

  testWidgets('4 seçenek: alt sayfa radyo listesi; seçim sayfayı kapatır '
      've değeri bildirir', (tester) async {
    int? selected;
    await tester.pumpWidget(_host(
      SettingsChoiceTile<int>(
        title: 'Sarma',
        value: 10,
        options: const [5, 10, 15, 30],
        labelOf: (v) => '$v sn',
        onChanged: (v) => selected = v,
      ),
    ));

    expect(find.byType(SegmentedButton<int>), findsNothing);

    await tester.tap(find.text('Sarma'));
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<int>), findsNWidgets(4));
    // Radyo satırı 48 dp+ dokunma hedefidir (varsayılan ListTile yüksekliği).
    expect(
      tester.getSize(find.byType(RadioListTile<int>).first).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('30 sn'));
    await tester.pumpAndSettle();

    expect(selected, 30);
    // Alt sayfa kapandı.
    expect(find.byType(RadioListTile<int>), findsNothing);
  });

  testWidgets('SettingsSwitchTile alt açıklamayı gösterir ve değeri '
      'bildirir', (tester) async {
    bool? toggled;
    await tester.pumpWidget(_host(
      SettingsSwitchTile(
        title: 'Anahtar',
        subtitle: 'alt açıklama',
        value: false,
        onChanged: (v) => toggled = v,
      ),
    ));

    expect(find.text('alt açıklama'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(toggled, true);
  });

  testWidgets('SettingsGroupCard başlığı ve çocuklarını kart yüzeyinde '
      'çizer', (tester) async {
    await tester.pumpWidget(_host(
      SettingsGroupCard(
        title: 'Grup',
        children: const [Text('satır')],
      ),
    ));

    expect(find.text('Grup'), findsOneWidget);
    expect(find.text('satır'), findsOneWidget);
    // Kart yüzeyi: surfaceContainerLow + 16 radiusContainer'ı bulunur.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).borderRadius ==
                BorderRadius.circular(16),
      ),
      findsOneWidget,
    );
  });
}