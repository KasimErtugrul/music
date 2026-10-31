// Gün 14: tema varyantı golden testleri.
//
// Şartname: «Açık, koyu, AMOLED ve yüksek kontrast için golden testler».
//
// Yöntem: Ayarlar ana sayfası, ThemeEngine'in ürettiği gerçek temalarla
// (ThemeController'a ihtiyaç yok — zamanlayıcı yok) 4 varyantta çizilir ve
// test/goldens/ altındaki PNG'lerle karşılaştırılır.
//
// Karşılaştırıcı toleranslıdır (Windows/Linux piksel düzeyi anti-aliasing
// farklarına dayanıklı): kanal başına 8'den fazla sapan ve görüntünün
// %2'sinden fazlasını etkileyen piksel varsa test KIRILIR. Gerçek tema
// gerilemeleri (yanlış yüzey rengi, yanlış kontrast) yüzlerce binlerce
// pikseli saptırır — tolerans onları asla gizlemez.
//
// PNG üretimi (yalnız baseline değişince): flutter test
//   --update-goldens test/widgets/settings_theme_golden_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/settings_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettingsRepo implements SettingsRepository {
  @override
  Future<AppSettingsModel> load() async =>
      const AppSettingsModel(languageCode: 'system');

  @override
  Future<void> setString(String key, String value) async {}
}

/// Kanal başına toleranslı golden karşılaştırıcı.
///
/// LocalFileComparator'den tek fark [compare]: ham RGBA farkında, kanal
/// başına [_maxChannelDelta] içindeki sapmaları piksel saymaz; toplam sapma
/// oranı [_maxDiffRatio] altındaysa eşleşme sayar. Boyut farkı yine kırılır.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const int _maxChannelDelta = 8;
  static const double _maxDiffRatio = 0.02;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final a = await _decodeRgba(imageBytes);
    final b = await _decodeRgba(Uint8List.fromList(goldenBytes));
    if (a.length != b.length) return false; // farklı boyut

    var differing = 0;
    for (var i = 0; i < a.length; i += 4) {
      if ((a[i] - b[i]).abs() > _maxChannelDelta ||
          (a[i + 1] - b[i + 1]).abs() > _maxChannelDelta ||
          (a[i + 2] - b[i + 2]).abs() > _maxChannelDelta ||
          (a[i + 3] - b[i + 3]).abs() > _maxChannelDelta) {
        differing++;
      }
    }
    final totalPixels = a.length ~/ 4;
    return differing <= totalPixels * _maxDiffRatio;
  }

  Future<Uint8List> _decodeRgba(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }
}

Widget _host(ThemeSettings settings) {
  final themeMode = settings.themeMode;
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    theme: ThemeEngine.light(settings),
    darkTheme: ThemeEngine.dark(settings),
    themeMode: themeMode,
    home: const SettingsHomePage(),
  );
}

Future<void> _seed() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);
  Get.put<SettingsController>(SettingsController(_FakeSettingsRepo()));
}

void _setSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    // basedir türetilmez: doğrudan test dosyasının dizini verilir (varsayılan
    // comparator makineye/test sırasına göre değişkendir). Böylece goldens/
    // her makinede test/widgets/goldens/ olarak çözümlenir.
    goldenFileComparator = _TolerantComparator(
      Directory.current.uri
          .resolve('test/widgets/settings_theme_golden_test.dart'),
    );
  });

  tearDown(() async {
    Get.reset();
  });

  testWidgets('açık tema: ayarlar ana sayfası golden', (tester) async {
    await _seed();
    _setSurface(tester);
    await tester.pumpWidget(_host(const ThemeSettings(
      themeMode: ThemeMode.light,
    )));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_home_light.png'),
    );
  });

  testWidgets('koyu tema: ayarlar ana sayfası golden', (tester) async {
    await _seed();
    _setSurface(tester);
    await tester.pumpWidget(_host(const ThemeSettings(
      themeMode: ThemeMode.dark,
    )));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_home_dark.png'),
    );
  });

  testWidgets('AMOLED: koyu + saf siyah yüzey golden', (tester) async {
    await _seed();
    _setSurface(tester);
    await tester.pumpWidget(_host(const ThemeSettings(
      themeMode: ThemeMode.dark,
      amoled: true,
    )));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_home_amoled.png'),
    );
  });

  testWidgets('yüksek kontrast: açık tema golden', (tester) async {
    await _seed();
    _setSurface(tester);
    await tester.pumpWidget(_host(const ThemeSettings(
      themeMode: ThemeMode.light,
      highContrast: true,
    )));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_home_high_contrast.png'),
    );
  });
}
