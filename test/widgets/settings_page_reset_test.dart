// Gün 13: «Bu sayfayı varsayılana döndür» AppBar eyleminin ve Çalma
// sayfasının üç grup yapısının widget testleri.
//
// Kapsam:
// - Çalma sayfası «Denetim · Başlangıç davranışı · Ses işleme» başlıklarıyla
//   bölümlenir
// - Sayfa sıfırlaması sayfadaki anahtarları fabrika değerine döndürür;
//   sayfada OLMAYAN hız/perde korunur (sayfa kapsamı sözleşmesi)
// - İptal edilirse diskte hiçbir şey değişmez, SnackBar çıkmaz
// - Kitaplık sayfası sıfırlaması modelin tamamını sıfırlar
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _seedPrefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    SettingsPersistence.playbackSettings: jsonEncode(<String, dynamic>{
      'seekIntervalSeconds': 30,
      'autoResume': true,
      'skipSilence': true,
      'speed': 1.5,
      'pitch': 0.9,
    }),
    SettingsPersistence.librarySettings: jsonEncode(<String, dynamic>{
      'scanOnStartup': false,
      'minDurationSeconds': 60,
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);
  return prefs;
}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: child,
    );

Map<String, dynamic> _playbackJson(SharedPreferences prefs) =>
    jsonDecode(prefs.getString(SettingsPersistence.playbackSettings)!)
        as Map<String, dynamic>;

Map<String, dynamic> _libraryJson(SharedPreferences prefs) =>
    jsonDecode(prefs.getString(SettingsPersistence.librarySettings)!)
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    Get.reset();
  });

  testWidgets('Çalma sayfası üç bölüm başlığıyla çizilir', (tester) async {
    await _seedPrefs();
    Get.put(PreferencesController(PreferencesRepositoryImpl(Get.find())));

    await tester.pumpWidget(_host(const PlaybackSettingsPage()));
    await tester.pumpAndSettle();

    // Gün 13 grupları: ilk bölüm ekranda; sonrakiler için liste kaydırılır
    // (ListView tembel kurulum — alttaki başlıklar henüz ağaçta değildir).
    expect(find.text('Denetim'), findsOneWidget);
    expect(find.text('Sarma süresi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Başlangıç davranışı'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Başlangıç davranışı'), findsOneWidget);
    expect(find.text('Uygulama açılınca otomatik devam et'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ses işleme'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ses işleme'), findsOneWidget);
  });

  testWidgets('onayla: sayfadaki anahtarlar sıfırlanır, hız/perde korunur',
      (tester) async {
    final prefs = await _seedPrefs();
    Get.put(PreferencesController(PreferencesRepositoryImpl(prefs)));

    await tester.pumpWidget(_host(const PlaybackSettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bu sayfayı varsayılana döndür'));
    await tester.pumpAndSettle();

    expect(find.text('Bu sayfadaki tüm ayarlar varsayılan değerlerine'
        ' döndürülecek. Bu işlem geri alınamaz.'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Sayfadaki anahtarlar fabrika değerinde:
    expect(_playbackJson(prefs)['seekIntervalSeconds'], 10);
    expect(_playbackJson(prefs)['autoResume'], false);
    expect(_playbackJson(prefs)['skipSilence'], false);
    // Sayfada OLMAYAN hız/perde kullanıcının tercihleri olarak kalır:
    expect(_playbackJson(prefs)['speed'], 1.5);
    expect(_playbackJson(prefs)['pitch'], 0.9);
    // Kitaplık ayarı bu sayfanın kapsamı dışıdır:
    expect(_libraryJson(prefs)['minDurationSeconds'], 60);

    expect(find.text('Ayarlar varsayılanlara döndürüldü'), findsOneWidget);
  });

  testWidgets('İptal edilirse diskte hiçbir şey değişmez', (tester) async {
    final prefs = await _seedPrefs();
    Get.put(PreferencesController(PreferencesRepositoryImpl(prefs)));

    await tester.pumpWidget(_host(const PlaybackSettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bu sayfayı varsayılana döndür'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    expect(_playbackJson(prefs)['seekIntervalSeconds'], 30);
    expect(_playbackJson(prefs)['skipSilence'], true);
    expect(find.text('Ayarlar varsayılanlara döndürüldü'), findsNothing);
  });

  testWidgets('Kitaplık sayfası: onayla modelin tamamı sıfırlanır',
      (tester) async {
    final prefs = await _seedPrefs();
    Get.put(PreferencesController(PreferencesRepositoryImpl(prefs)));

    await tester.pumpWidget(_host(const LibrarySettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bu sayfayı varsayılana döndür'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(_libraryJson(prefs)['scanOnStartup'], true);
    expect(_libraryJson(prefs)['minDurationSeconds'], 0);
    // Çalma ayarları kitaplık sayfasının kapsamı dışıdır:
    expect(_playbackJson(prefs)['skipSilence'], true);
    expect(find.text('Ayarlar varsayılanlara döndürüldü'), findsOneWidget);
  });
}
