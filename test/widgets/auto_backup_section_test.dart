// Aşama 6: AutoBackupSection widget testleri.
//
// Bölüm, sahte repo'larla kurulan GERÇEK AutoBackupController ile
// pompalanır; anahtar tercih yazımı, "şimdi yedekle" akışı ve geri
// yükleme/silme diyaloğu doğrulanır. SnackBar otomatik kapanış
// zamanlayıcısı, test bitmeden ileri pump ile tüketilir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/ui/widgets/auto_backup_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAutoRepo extends Mock implements AutoBackupRepository {}

class _MockBackupRepo extends Mock implements BackupRepository {}

class _MockLibraryRepo extends Mock implements LibraryRepository {}

const BackupModel _emptyModel = BackupModel(
  playlists: [],
  favorites: [],
  customThemes: [],
  equalizerPresets: [],
  settings: {},
);

AutoBackupEntry _entry(DateTime at, {int size = 2048}) => AutoBackupEntry(
      fileName:
          'resonance_auto_${at.millisecondsSinceEpoch}.json',
      path: '/tmp/resonance_auto_${at.millisecondsSinceEpoch}.json',
      createdAt: at,
      sizeBytes: size,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAutoRepo autoRepo;
  late _MockBackupRepo backupRepo;
  late _MockLibraryRepo libraryRepo;

  setUpAll(() {
    registerFallbackValue(0);
    registerFallbackValue(_emptyModel);
    registerFallbackValue(_entry(DateTime(2026)));
  });

  setUp(() {
    autoRepo = _MockAutoRepo();
    backupRepo = _MockBackupRepo();
    libraryRepo = _MockLibraryRepo();

    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
    when(() => autoRepo.create())
        .thenAnswer((_) async => _entry(DateTime(2026, 1, 30, 12)));
    when(() => autoRepo.prune(any())).thenAnswer((_) async {});
    when(() => backupRepo.export()).thenAnswer((_) async => _emptyModel);
    when(() => libraryRepo.rescan()).thenAnswer((_) async {});
    // restore/deleteBackup akışlarında çağrılan yöntemler: stub'sız mock
    // çağrısı null döner ve 'Null is not a subtype of Future<void>' üretir.
    when(() => backupRepo.import(any())).thenAnswer((_) async {});
    when(() => autoRepo.delete(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
     Get.reset();
  });

  Future<AutoBackupController> buildController({
    Map<String, Object> prefsInit = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsInit);
    final prefs = await SharedPreferences.getInstance();
    final ctrl = Get.put<AutoBackupController>(
      AutoBackupController(
        autoRepo: autoRepo,
        backupRepo: backupRepo,
        libraryRepo: libraryRepo,
        prefs: prefs,
        now: () => DateTime(2026, 1, 30, 12),
      ),
    );
    await ctrl.refreshBackups();
    return ctrl;
  }

  Future<void> pumpSection(WidgetTester tester, AutoBackupController ctrl) {
    // Bölüm uzundur; tüm satırların ekran içinde kalarak hit-test
    // edilebilmesi için test yüzeyini büyüt.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: <Widget>[AutoBackupSection(controller: ctrl)],
          ),
        ),
      ),
    );
  }

  testWidgets('yedek yoksa boş durum metni gösterilir', (tester) async {
    final ctrl = await buildController();
    await pumpSection(tester, ctrl);
    expect(find.text('No stored backups yet'), findsOneWidget);
    expect(find.text('Automatic backup'), findsOneWidget);
  });

  testWidgets('kapalı tercihte anahtar kapalı; açınca kalıcıya yazılır',
      (tester) async {
    final ctrl = await buildController(
      prefsInit: <String, Object>{'settings_auto_backup_enabled': false},
    );
    await pumpSection(tester, ctrl);

    final sw = find.byType(SwitchListTile);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    // Kapalıyken "şimdi yedekle" düğmesi devre dışıdır.
    expect(tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Back up now'),
    ).onPressed, isNull);

    await tester.tap(sw);
    await tester.pumpAndSettle();

    expect(ctrl.enabled.value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_auto_backup_enabled'), isTrue);
  });

  testWidgets('şimdi yedekle: create çağrılır, başarı bildirimi gösterilir',
      (tester) async {
    final ctrl = await buildController();
    await pumpSection(tester, ctrl);

    await tester.tap(find.text('Back up now'));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => autoRepo.create()).called(1);
    verify(() => autoRepo.prune(7)).called(1);
    expect(find.text('Automatic backup created'), findsOneWidget);

    // SnackBar'ın otomatik kapanış zamanlayıcısı testi asıya düşürmesin.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('yedek satırları tarih ve boyutla çizilir', (tester) async {
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[
          _entry(DateTime(2026, 1, 29, 12), size: 2048),
          _entry(DateTime(2026, 1, 28, 9), size: 1024),
        ]);
    final ctrl = await buildController();
    await pumpSection(tester, ctrl);

    expect(find.text('29.01.2026 12:00'), findsOneWidget);
    expect(find.text('28.01.2026 09:00'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('geri yükleme: onay sonrası import + rescan çağrılır',
      (tester) async {
    final e1 = _entry(DateTime(2026, 1, 29, 12));
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[e1]);
    when(() => autoRepo.read(e1)).thenAnswer((_) async => _emptyModel);
    final ctrl = await buildController();
    await pumpSection(tester, ctrl);

    await tester.tap(find.byIcon(Icons.restore));
    await tester.pumpAndSettle();
    expect(find.text('Restore this backup?'), findsOneWidget);

    await tester.tap(find.text('Import & Overwrite'));
    await tester.pumpAndSettle();

    verify(() => backupRepo.import(_emptyModel)).called(1);
    verify(() => libraryRepo.rescan()).called(1);
    expect(find.text('Backup restored'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('silme: onay sonrası delete çağrılır, liste boşalır',
      (tester) async {
    final e1 = _entry(DateTime(2026, 1, 29, 12));
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[e1]);
    final ctrl = await buildController();
    await pumpSection(tester, ctrl);

    // Silme sonrası tazelemede boş liste dönsün.
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this backup?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => autoRepo.delete(e1)).called(1);
    expect(find.text('Backup deleted'), findsOneWidget);
    expect(find.text('No stored backups yet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });
}
