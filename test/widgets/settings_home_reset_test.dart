// Gün 6: Ayarlar ana sayfasındaki "Tüm ayarları sıfırla" akışının widget
// testi. Satırın görünürlüğü, onay diyaloğu (İptal/onay), disk etkisi ve
// SnackBar geri bildirimi doğrulanır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_persistence.dart';
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

Future<SharedPreferences> _seedPrefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    SettingsPersistence.languageCode: 'tr',
    SettingsPersistence.playbackSettings: '{"seekIntervalSeconds":30}',
    SettingsPersistence.lastBackupAt: 1700000000000,
  });
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    Get.reset();
  });

  testWidgets('sıfırla satırı görünür; onayla tüm ayar anahtarları kaldırılır'
      ' ve SnackBar gösterilir', (tester) async {
    final prefs = await _seedPrefs();
    Get.put<SettingsController>(SettingsController(_FakeSettingsRepo()));
    Get.put<PreferencesController>(
      PreferencesController(PreferencesRepositoryImpl(prefs)),
    );

    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('tr'),
      home: SettingsHomePage(),
    ));
    await tester.pumpAndSettle();

    // Satır liste altındadır; görünene dek kaydır.
    await tester.scrollUntilVisible(
      find.text('Tüm ayarları sıfırla'),
      200,
      // not: .first TextField'ın iç scrollable'ıdır; ana liste .last'tır.
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Tüm ayarları sıfırla'), findsOneWidget);

    await tester.tap(find.text('Tüm ayarları sıfırla'));
    await tester.pumpAndSettle();

    // Onay diyaloğu: taban l10n dizgeleri canlandı.
    expect(
      find.text(
        'Tüm ayarları varsayılana sıfırlamak istediğinize emin misiniz?'
        ' Bu işlem geri alınamaz.',
      ),
      findsOneWidget,
    );
    expect(find.text('İptal'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Disk: yedeklenen ayar anahtarları boş; zaman damgası korunur.
    expect(prefs.getString(SettingsPersistence.languageCode), isNull);
    expect(prefs.getString(SettingsPersistence.playbackSettings), isNull);
    expect(prefs.getInt(SettingsPersistence.lastBackupAt), 1700000000000);

    // Geri bildirim:
    expect(find.text('Ayarlar varsayılanlara döndürüldü'), findsOneWidget);
  });

  testWidgets('İptal edilirse diskte hiçbir şey değişmez', (tester) async {
    final prefs = await _seedPrefs();
    Get.put<SettingsController>(SettingsController(_FakeSettingsRepo()));
    Get.put<PreferencesController>(
      PreferencesController(PreferencesRepositoryImpl(prefs)),
    );

    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('tr'),
      home: SettingsHomePage(),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tüm ayarları sıfırla'),
      200,
      // not: .first TextField'ın iç scrollable'ıdır; ana liste .last'tır.
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tüm ayarları sıfırla'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    expect(prefs.getString(SettingsPersistence.languageCode), 'tr');
    expect(
      prefs.getString(SettingsPersistence.playbackSettings),
      '{"seekIntervalSeconds":30}',
    );
    // SnackBar çıkmadı:
    expect(find.text('Ayarlar varsayılanlara döndürüldü'), findsNothing);
  });
}