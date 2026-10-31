// Gün 16: ayar bilgi balonları (SettingsInfoBadge + SettingsInfoSheet)
// widget testleri.
//
// Kapsam:
// - info verilmezse rozet çizilmez (geriye dönük uyumluluk sözleşmesi)
// - rozet dokunuşu bilgi alt sayfasını açar: ayarın adı başlıkta, açıklama
//   gövdede
// - rozet dokunuşu satırın KENDİ eylemini tetiklemez: anahtarın değeri
//   değişmez, SettingsTile'ın onTap'i çalışmaz
// - Tamam düğmesi alt sayfayı kapatır, satır yerinde kalır
// - ChoiceTile'ın bölümlü sunumunda rozet başlıkta çizilir, segmentler bozulmaz
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_info_sheet.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_tile.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(body: ListView(children: [child])),
    );

void main() {
  testWidgets('info verilmezse rozet çizilmez (geriye dönük uyumluluk)',
      (tester) async {
    await tester.pumpWidget(_host(SettingsSwitchTile(
      title: 'Anahtar',
      value: false,
      onChanged: (_) {},
    )));
    await tester.pump();

    expect(find.byType(SettingsInfoBadge), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('rozet dokunuşu balonu açar; anahtar değişmez, Tamam kapatır',
      (tester) async {
    var value = false;
    await tester.pumpWidget(_host(SettingsSwitchTile(
      title: 'Kulaklık',
      value: value,
      onChanged: (v) => value = v,
      info: 'Kulaklık çıkınca duraklatır.',
    )));
    await tester.pump();

    expect(find.byType(SettingsInfoBadge), findsOneWidget);

    await tester.tap(find.byType(SettingsInfoBadge));
    await tester.pumpAndSettle();

    // Balon: ayar adı başlıkta (satırdaki başlıkla birlikte 2 kez), açıklama
    // gövdede. Anahtar tetiklenmedi.
    expect(find.text('Kulaklık'), findsNWidgets(2));
    expect(find.text('Kulaklık çıkınca duraklatır.'), findsOneWidget);
    expect(value, isFalse);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.text('Kulaklık çıkınca duraklatır.'), findsNothing);
    // Balon kapandı; satır ve rozeti yerinde duruyor.
    expect(find.byType(SettingsInfoBadge), findsOneWidget);
  });

  testWidgets('SettingsTile: rozet satırın onTap ini tetiklemez',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(SettingsTile(
      title: 'Kapak önbelleği',
      onTap: () => taps++,
      info: 'Önbelleği temizler.',
    )));
    await tester.pump();

    await tester.tap(find.byType(SettingsInfoBadge));
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(find.text('Önbelleği temizler.'), findsOneWidget);
  });

  testWidgets('SettingsTile: info yoksa satır dokunuşu eskisi gibi çalışır',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(SettingsTile(
      title: 'Ekolayzır',
      onTap: () => taps++,
    )));
    await tester.pump();

    await tester.tap(find.text('Ekolayzır'));
    await tester.pump();

    expect(taps, 1);
    expect(find.byType(SettingsInfoBadge), findsNothing);
  });

  testWidgets('ChoiceTile ≤3: rozet başlıkta çizilir, segment seçimi bozulmaz',
      (tester) async {
    var secilen = 'seed';
    await tester.pumpWidget(_host(SettingsChoiceTile<String>(
      title: 'Kaynak',
      value: secilen,
      options: const ['seed', 'system'],
      labelOf: (v) => v,
      onChanged: (v) => secilen = v,
      info: 'Renk kaynağı.',
    )));
    await tester.pump();

    expect(find.byType(SettingsInfoBadge), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);

    await tester.tap(find.text('system'));
    await tester.pump();
    expect(secilen, 'system');
  });

  testWidgets('ChoiceTile >3: rozet satırda çizilir, alt sayfa dokunuşunu çalmaz',
      (tester) async {
    await tester.pumpWidget(_host(SettingsChoiceTile<int>(
      title: 'Sarma',
      subtitle: 'Sarma süresi',
      value: 10,
      options: const [5, 10, 15, 30],
      labelOf: (v) => '$v sn',
      onChanged: (_) {},
      info: 'Sarma adımı.',
    )));
    await tester.pump();

    expect(find.byType(SettingsInfoBadge), findsOneWidget);

    // Rozete dokunmak seçim alt sayfasını değil bilgi balonunu açar.
    await tester.tap(find.byType(SettingsInfoBadge));
    await tester.pumpAndSettle();
    expect(find.text('Sarma adımı.'), findsOneWidget);
    expect(find.text('30 sn'), findsNothing); // seçim listesi açılmadı

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Sarma adımı.'), findsNothing);
  });
}
