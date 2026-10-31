// Gün 13: Galeri + Gelişmiş birleşiminin («Görünüm» sayfası) widget
// testleri. Karar: «Gelişmiş» sayfa Görünüm sayfasına birleşir.
//
// Kapsam:
// - AppBar sayfanın adını gösterir; canlı önizleme kaydırılan listenin
//   DIŞINDADIR (sabit)
// - Tema modu artık 4 seçenekli tek denetimdir (Sistem/Açık/Koyu/AMOLED);
//   AMOLED seçimi modu koyuya alır ve saf siyah yüzeyi açar
// - Sayfa sıfırlaması sayfadaki tema alanlarını sıfırlar; yazı tipi,
//   yazı ölçeği ve liste görünümü (kendi sayfalarında yaşar) korunur
// - Kayıt defterindeki tüm görünüm girdileri birleşik sayfaya gider
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/settings/settings_keys.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_gallery_page.dart';
import 'package:resonance/presentation/ui/widgets/theme_preview_card.dart';

class _MockThemeRepository extends Mock implements ThemeRepository {}

class _MockLibraryRepository extends Mock implements LibraryRepository {}

class _MockCustomThemeRepository extends Mock
    implements CustomThemeRepository {}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockThemeRepository repo;
  late _MockLibraryRepository libRepo;
  late _MockCustomThemeRepository customRepo;
  late StreamController<MediaItem?> playerStream;
  late ThemeController controller;

  setUpAll(() {
    registerFallbackValue(const ThemeSettings());
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockThemeRepository();
    libRepo = _MockLibraryRepository();
    customRepo = _MockCustomThemeRepository();
    when(() => repo.loadActiveTheme()).thenAnswer((_) async => null);
    when(() => repo.saveActiveTheme(any())).thenAnswer((_) async {});
    when(() => libRepo.artwork(any())).thenAnswer((_) async => null);
    when(() => customRepo.watchAll())
        .thenAnswer((_) => const Stream<List<CustomThemeModel>>.empty());

    playerStream = StreamController<MediaItem?>();
    controller = ThemeController(repo, playerStream.stream, libRepo);
    Get.put(controller);
    Get.put<CustomThemeRepository>(customRepo);
  });

  tearDown(() {
    // Periodik zamanlayıcıyı iptal etmezsek flutter_test "pending timer"
    // hatası verir (theme_controller_test ile aynı desen).
    controller.dispose();
    playerStream.close();
    Get.reset();
  });

  testWidgets('AppBar sayfa adını gösterir; önizleme sabittir',
      (tester) async {
    await tester.pumpWidget(_host(const ThemeGalleryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Görünüm ve tema'), findsOneWidget);
    // Gün 13: sabit canlı önizleme — kaydırılan listenin DIŞINDA.
    expect(find.byType(ThemePreviewCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(ThemePreviewCard),
      ),
      findsNothing,
    );
    // Bölümler tek sayfada: ilk ekran + kaydırılarak görünenler.
    expect(find.text('Tema modu'), findsWidgets);
    expect(find.text('Renk'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Şekil ve yoğunluk'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Şekil ve yoğunluk'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hazır paletler'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Hazır paletler'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Özel temalar'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Özel temalar'), findsOneWidget);
  });

  testWidgets('mod: alt sayfada 4 seçenek; AMOLED koyu + saf siyah açar',
      (tester) async {
    await tester.pumpWidget(_host(const ThemeGalleryPage()));
    await tester.pumpAndSettle();

    // Karar gereği Gelişmiş sayfasındaki ayrı AMOLED anahtarı kaldırıldı;
    // AMOLED artık mod seçeneğidir. «Tema modu» hem bölüm başlığı hem
    // döşeme başlığıdır; döşeme ağaçta sonradan gelir (.last).
    await tester.tap(find.text('Tema modu').last);
    await tester.pumpAndSettle();

    expect(find.text('Sistem'), findsWidgets);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Koyu'), findsWidgets);
    expect(find.text('AMOLED'), findsOneWidget);

    await tester.tap(find.text('AMOLED'));
    await tester.pumpAndSettle();

    final s = controller.settings.value;
    expect(s.themeMode, ThemeMode.dark);
    expect(s.amoled, isTrue);
  });

  testWidgets('onayla: sayfa alanları sıfırlanır; yazı tipi/ölçek/liste'
      ' korunur', (tester) async {
    controller.setSettings(const ThemeSettings(
      themeMode: ThemeMode.dark,
      amoled: true,
      themeSource: 'artwork',
      seedColor: Color(0xFF123456),
      highContrast: true,
      roundedCorners: false,
      scheduledDarkEnabled: true,
      fontFamily: 'XFont',
      textScale: 1.3,
      listViewMode: 'grid',
    ));
    await tester.pumpWidget(_host(const ThemeGalleryPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bu sayfayı varsayılana döndür'));
    await tester.pumpAndSettle();
    // Sabit önizleme kartında da bir FilledButton olduğu için onay
    // düğmesi diyalog kapsamında aranır.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ));
    await tester.pumpAndSettle();

    final s = controller.settings.value;
    // Sayfadaki alanlar fabrika değerinde:
    expect(s.themeMode, ThemeMode.system);
    expect(s.amoled, isFalse);
    expect(s.themeSource, 'seed');
    expect(s.highContrast, isFalse);
    expect(s.roundedCorners, isTrue);
    expect(s.scheduledDarkEnabled, isFalse);
    // Kendi sayfalarında yaşayan tercihler korunur:
    expect(s.fontFamily, 'XFont');
    expect(s.textScale, 1.3);
    expect(s.listViewMode, 'grid');
  });

  test('kayıt defteri: tüm görünüm girdileri birleşik sayfaya gider', () {
    for (final key in <String>[
      SettingsKeys.themeMode,
      SettingsKeys.themeColorSource,
      SettingsKeys.themeAmoled,
      SettingsKeys.themeHighContrast,
    ]) {
      final entry =
          SettingsRegistry.all.firstWhere((e) => e.key == key);
      expect(entry.pageBuilder, isNotNull, reason: key);
      expect(entry.pageBuilder!(), isA<ThemeGalleryPage>(), reason: key);
    }
  });
}
