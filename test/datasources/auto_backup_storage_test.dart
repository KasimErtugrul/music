// Aşama 6: AutoBackupStorage birim testleri.
//
// Gerçek dosya sistemiyle (geçici dizin) çalışır; path_provider eklentisi
// yoktur çünkü resolveDir enjekte edilir. Böylece yazma/okuma/budama
// davranışı uçtan uca doğrulanır.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/models/backup_model.dart';

BackupModel _model({String playlistName = 'Drive'}) => BackupModel(
      version: 1,
      playlists: <BackupPlaylist>[
        BackupPlaylist(
          name: playlistName,
          songs: const <BackupSong>[
            BackupSong(
              uri: '',
              path: '/m/1.flac',
              title: 'A',
              durationMs: 1000,
            ),
          ],
        ),
      ],
      favorites: const <BackupSong>[],
      customThemes: const <BackupTheme>[],
      equalizerPresets: const <BackupEqualizerPreset>[],
      settings: const <String, dynamic>{'settings_lang': 'en'},
    );

void main() {
  late Directory temp;
  late AutoBackupStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('auto_backup_test');
    storage = AutoBackupStorage(resolveDir: () async => temp);
  });

  tearDown(() async {
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  group('AutoBackupStorage (Aşama 6)', () {
    test('olmayan dizinde liste boş döner; hata fırlatmaz', () async {
      final missing = Directory('${temp.parent.path}/yok_boyle_dizin');
      final s = AutoBackupStorage(resolveDir: () async => missing);
      expect(await s.list(), isEmpty);
    });

    test('write: dosya oluşur ve kayıt döner', () async {
      final e = await storage.write(_model(playlistName: 'One'));
      expect(await File(e.path).exists(), isTrue);
      expect(e.fileName, startsWith('resonance_auto_'));
      expect(e.fileName, endsWith('.json'));
      expect(e.sizeBytes, greaterThan(0));
    });

    test('write: aynı milisaniyede iki yedek çakışmaz', () async {
      final a = await storage.write(_model());
      final b = await storage.write(_model());
      expect(a.fileName, isNot(b.fileName));
      expect(await storage.list(), hasLength(2));
    });

    test('list: en yeniden eskiye sıralı döner', () async {
      final e1 = await storage.write(_model(playlistName: 'One'));
      // Aynı-ms çakıştırmaya karşı sıralamanın belirleyici olması için bekle.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final e2 = await storage.write(_model(playlistName: 'Two'));
      final list = await storage.list();
      expect(list, hasLength(2));
      expect(list[0].fileName, e2.fileName);
      expect(list[1].fileName, e1.fileName);
    });

    test('list: yabancı dosyalar ve alt dizinler yok sayılır', () async {
      await storage.write(_model());
      await File('${temp.path}/resonance_manual.json').writeAsString('{}');
      await File('${temp.path}/not_a_backup.json').writeAsString('{}');
      await Directory('${temp.path}/subdir').create();
      final list = await storage.list();
      expect(list, hasLength(1));
    });

    test('read: yazılan model geri okunur', () async {
      final e = await storage.write(_model(playlistName: 'Restore'));
      final model = await storage.read(e);
      expect(model, isNotNull);
      expect(model!.playlists.single.name, 'Restore');
      expect(model.settings['settings_lang'], 'en');
      expect(model.version, 1);
    });

    test('read: bozuk dosya null döner; liste yine de onu gösterir', () async {
      await File('${temp.path}/resonance_auto_123456.json')
          .writeAsString('{bozuk');
      final list = await storage.list();
      expect(list, hasLength(1));
      expect(await storage.read(list.single), isNull);
    });

    test('prune: en yeni N yedek kalır, eskiler diskten silinir', () async {
      for (var i = 0; i < 5; i++) {
        await storage.write(_model(playlistName: 'P$i'));
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
      await storage.prune(2);
      final list = await storage.list();
      expect(list, hasLength(2));
      final jsonFiles = await temp
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .toList();
      expect(jsonFiles, hasLength(2));
    });

    test('prune: yedek sayısı sınırdan azsa hiçbiri silinmez', () async {
      await storage.write(_model());
      await storage.prune(10);
      expect(await storage.list(), hasLength(1));
    });

    test('delete: dosya kaldırılır; tekrar silmek hata vermez', () async {
      final e = await storage.write(_model());
      await storage.delete(e);
      expect(await File(e.path).exists(), isFalse);
      await storage.delete(e); // idempotent
    });
  });
}
