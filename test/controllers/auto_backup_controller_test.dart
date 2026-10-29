// Aşama 6: AutoBackupController birim testleri.
//
// Zamanlama sözleşmesi, kalıcı tercihler, saklama politikası ve geri
// yükleme akışı mocktail ile doğrulanır. `now` enjekte edilir; testler
// sabit zamanla deterministik çalışır.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
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

AutoBackupEntry _entry(int ms) => AutoBackupEntry(
      fileName: 'resonance_auto_$ms.json',
      path: '/tmp/resonance_auto_$ms.json',
      createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
      sizeBytes: 42,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAutoRepo autoRepo;
  late _MockBackupRepo backupRepo;
  late _MockLibraryRepo libraryRepo;
  // Sabit "şimdi": 30.01.2026 12:00.
  final DateTime now = DateTime(2026, 1, 30, 12);

  setUpAll(() {
    // mocktail: any() kullanılan her tip için fallback zorunludur.
    registerFallbackValue(0);
    registerFallbackValue(_emptyModel);
    registerFallbackValue(_entry(0));
  });

  setUp(() {
    autoRepo = _MockAutoRepo();
    backupRepo = _MockBackupRepo();
    libraryRepo = _MockLibraryRepo();

    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
    when(() => autoRepo.create())
        .thenAnswer((_) async => _entry(now.millisecondsSinceEpoch));
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

  Future<AutoBackupController> build({
    Map<String, Object> prefsInit = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsInit);
    final prefs = await SharedPreferences.getInstance();
    return Get.put<AutoBackupController>(
      AutoBackupController(
        autoRepo: autoRepo,
        backupRepo: backupRepo,
        libraryRepo: libraryRepo,
        prefs: prefs,
        now: () => now,
      ),
    );
  }

  group('kalıcı tercihler', () {
    test('varsayılanlar: açık, günlük, 7 yedek, son yedek yok', () async {
      final c = await build();
      expect(c.enabled.value, isTrue);
      expect(c.frequency.value, AutoBackupFrequency.daily);
      expect(c.keepCount.value, 7);
      expect(c.lastRunAt.value, isNull);
    });

    test('kalıcı tercihler açılışta yüklenir', () async {
      final last = now.subtract(const Duration(hours: 5));
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_enabled': false,
        'settings_auto_backup_frequency': 'weekly',
        'settings_auto_backup_keep': 3,
        'settings_auto_backup_last': last.millisecondsSinceEpoch,
      });
      expect(c.enabled.value, isFalse);
      expect(c.frequency.value, AutoBackupFrequency.weekly);
      expect(c.keepCount.value, 3);
      expect(c.lastRunAt.value, last);
    });

    test('geçersiz sıklık/keep değeri varsayılana döner', () async {
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_frequency': 'monthly',
        'settings_auto_backup_keep': 42,
      });
      expect(c.frequency.value, AutoBackupFrequency.daily);
      expect(c.keepCount.value, 7);
    });

    test('setEnabled/setFrequency/setKeepCount kalıcıya yazılır', () async {
      final c = await build();
      await c.setEnabled(false);
      await c.setFrequency(AutoBackupFrequency.weekly);
      await c.setKeepCount(10);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_auto_backup_enabled'), isFalse);
      expect(prefs.getString('settings_auto_backup_frequency'), 'weekly');
      expect(prefs.getInt('settings_auto_backup_keep'), 10);
    });
  });

  group('zamanlama', () {
    test('ilk açılışta (son yedek yok) hemen yedek alır ve budar', () async {
      final c = await build();
      await c.ensureScheduledBackup();
      verify(() => autoRepo.create()).called(1);
      verify(() => autoRepo.prune(7)).called(1);
    });

    test('günlük sıklık dolmadan yedek alınmaz', () async {
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_last':
            now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      });
      await c.ensureScheduledBackup();
      verifyNever(() => autoRepo.create());
    });

    test('günlük sıklık dolduğunda yedek alınır', () async {
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_last':
            now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      });
      await c.ensureScheduledBackup();
      verify(() => autoRepo.create()).called(1);
    });

    test('haftalık sıklık: 3 gün önceki yedek bekler', () async {
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_frequency': 'weekly',
        'settings_auto_backup_last':
            now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      });
      await c.ensureScheduledBackup();
      verifyNever(() => autoRepo.create());
    });

    test('haftalık sıklık: 8 gün önceki yedek alınır', () async {
      final c = await build(prefsInit: <String, Object>{
        'settings_auto_backup_frequency': 'weekly',
        'settings_auto_backup_last':
            now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      });
      await c.ensureScheduledBackup();
      verify(() => autoRepo.create()).called(1);
    });

    test('kapalıyken ensureScheduledBackup hiçbir şey yapmaz', () async {
      final c =
          await build(prefsInit: <String, Object>{
        'settings_auto_backup_enabled': false,
      });
      await c.ensureScheduledBackup();
      verifyNever(() => autoRepo.create());
    });

    test('runNow sıklıktan bağımsız çalışır, son yedeği günceller', () async {
      final c = await build();
      final ok = await c.runNow();
      expect(ok, isTrue);
      verify(() => autoRepo.create()).called(1);
      verify(() => autoRepo.prune(7)).called(1);
      expect(c.lastRunAt.value, now);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings_auto_backup_last'),
          now.millisecondsSinceEpoch);
    });
  });

  group('geri yükleme ve silme', () {
    test('restore: model okunur, import + rescan çağrılır', () async {
      final c = await build();
      final entry = _entry(1000);
      when(() => autoRepo.read(entry)).thenAnswer((_) async => _emptyModel);
      final ok = await c.restore(entry);
      expect(ok, isTrue);
      verify(() => backupRepo.import(_emptyModel)).called(1);
      verify(() => libraryRepo.rescan()).called(1);
    });

    test('restore: bozuk yedek (null) false döner, import çağrılmaz',
        () async {
      final c = await build();
      final entry = _entry(1001);
      when(() => autoRepo.read(entry)).thenAnswer((_) async => null);
      final ok = await c.restore(entry);
      expect(ok, isFalse);
      verifyNever(() => backupRepo.import(any()));
      verifyNever(() => libraryRepo.rescan());
    });

    test('deleteBackup: siler ve listeyi tazeler', () async {
      final c = await build();
      final e1 = _entry(2000);
      final e2 = _entry(3000);
      when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[e2]);
      await c.deleteBackup(e1);
      verify(() => autoRepo.delete(e1)).called(1);
      expect(c.backups.toList(), <AutoBackupEntry>[e2]);
    });
  });
}
