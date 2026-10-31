// Gün 14: iki bölmeli ayarlar yerleşiminin widget testleri.
//
// Kapsam:
// - Compact (< 840 dp): davranış değişmedi — satır dokunuşu sayfayı ROUTE
//   olarak açar, yer tutucu yoktur
// - Geniş ekran (>= 840 dp, M3 expanded): sol liste + sağ ayrıntı bölmesi;
//   seçim yoksa «Soldan bir ayar seçin» yer tutucusu çizilir
// - Geniş ekranda satır dokunuşu route açMAZ: ayrıntı sayfası sağ bölmede
//   çizilir (ana listenin AppBar'ı ve satırı hâlâ ağaçtadır) ve seçim
//   değişince bölme içeriği değişir
// - Arama sonucu da geniş ekranda sağ bölmeyi doldurur (registry pageBuilder)
//
// Eşik notu: test yüzeyi fiziksel pikseldir (dpr 1.0). 1200 genişlik
// Responsive.expandedBreakpoint (840) üzerindedir; 400 compact kalır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
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

Future<void> _seedControllers() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);
  Get.put<SettingsController>(SettingsController(_FakeSettingsRepo()));
  // Ayrıntı bölmesine açılacak sayfalar (ör. Çalma) PreferencesController
  // bulur; compact/geniş akışlar gerçek repo uygulamasıyla kurulur.
  Get.put<PreferencesController>(
    PreferencesController(PreferencesRepositoryImpl(prefs)),
  );
}

Widget _host() => GetMaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const SettingsHomePage(),
    );

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() async {
    Get.reset();
  });

  testWidgets('compact: yer tutucu yok; satır sayfayı route olarak açar',
      (tester) async {
    _setSurface(tester, const Size(400, 800));
    await _seedControllers();

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Compact'ta sağ bölme/yer tutucu yoktur:
    expect(find.text('Soldan bir ayar seçin'), findsNothing);

    await tester.tap(find.text('Oynatma'));
    await tester.pumpAndSettle();

    // Ayrıntı sayfası ROUTE olarak açıldı: ana sayfa AppBar'ı artık ağaçta
    // değil (push edilen rota ekranı kaplar).
    expect(find.text('Ayarlar'), findsNothing);
    expect(find.text('Denetim'), findsOneWidget);
    expect(find.text('Sarma süresi'), findsOneWidget);
  });

  testWidgets('geniş ekran: yer tutucu çizilir; dokunma sağ bölmeyi doldurur'
      ' ve route açmaz', (tester) async {
    _setSurface(tester, const Size(1200, 800));
    await _seedControllers();

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Sol liste + sağ yer tutucu:
    expect(find.text('Soldan bir ayar seçin'), findsOneWidget);
    expect(find.text('Oynatma'), findsOneWidget);

    await tester.tap(find.text('Oynatma'));
    await tester.pumpAndSettle();

    // Route açılmadı: ana sayfa AppBar'ı hâlâ görünür; ayrıntı sayfası
    // sağ bölmede çizildi (bölüm başlığı + ilk satır).
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Denetim'), findsOneWidget);
    expect(find.text('Sarma süresi'), findsOneWidget);
    // Yer tutucu kalktı:
    expect(find.text('Soldan bir ayar seçin'), findsNothing);
    // «Oynatma» iki yerde: sol liste satırı + sağ bölmedeki AppBar başlığı.
    expect(find.text('Oynatma'), findsNWidgets(2));
  });

  testWidgets('geniş ekran: seçim değişince sağ bölme yeni sayfayı çizer',
      (tester) async {
    _setSurface(tester, const Size(1200, 800));
    await _seedControllers();

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oynatma'));
    await tester.pumpAndSettle();
    expect(find.text('Denetim'), findsOneWidget);

    // Üst gruplardaki «Ses» satırı da görünürdür (ekran dışı kaydırma
    // gerektirmez); seçim değişince bölme içeriği değişir.
    await tester.tap(find.text('Ses'));
    await tester.pumpAndSettle();

    // Çalma sayfası bölmeden kalktı; Ses sayfası geldi (Ekolayzer tile'ı).
    expect(find.text('Denetim'), findsNothing);
    expect(find.text('Ekolayzer'), findsOneWidget);
  });

  testWidgets('geniş ekran: arama sonucu sağ bölmeyi doldurur',
      (tester) async {
    _setSurface(tester, const Size(1200, 800));
    await _seedControllers();

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Arama: sonuç listesi nav listesinin yerini alır (Hakkında girdisi).
    await tester.enterText(find.byType(TextField), 'hakkında');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();

    // Hakkında sayfası sağ bölmede: sürüm satırı çizilir, yer tutucu yok.
    expect(find.text('Sürüm 1.0.0'), findsOneWidget);
    expect(find.text('Soldan bir ayar seçin'), findsNothing);
  });
}
