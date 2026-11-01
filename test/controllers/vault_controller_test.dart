import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resonance/data/models/banned_song_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/banned_song_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/vault_controller.dart';

SongModel _song(int id, String title) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: title,
      durationMs: 180000,
      sizeBytes: 4000000,
    );

/// Bellek içi sahte kasa deposu; akışı yayınlarla canlı tutar.
class _FakeBannedRepo implements BannedSongRepository {
  final _entries = <BannedSongModel>[];
  final _ctrl = StreamController<List<BannedSongModel>>.broadcast();

  void emit() {
    if (_ctrl.hasListener) {
      _ctrl.add(List.unmodifiable(_entries));
    }
  }

  @override
  Future<void> ban(SongModel song) async {
    _entries.removeWhere((e) => e.path == song.path);
    _entries.add(BannedSongModel(
      id: _entries.length + 1,
      songId: song.id,
      path: song.path,
      title: song.title,
      createdAt: DateTime(2026, 1, 1),
    ));
    emit();
  }

  @override
  Future<BanIndex> banIndex() async => BanIndex(
        ids: {for (final e in _entries) e.songId},
        paths: {for (final e in _entries) e.path},
      );

  @override
  Future<List<BannedSongModel>> getBanned() async =>
      List.unmodifiable(_entries);

  @override
  Stream<List<BannedSongModel>> watchBanned() => _ctrl.stream;

  @override
  Future<void> unban(BannedSongModel entry) async {
    _entries.removeWhere((e) => e.path == entry.path);
    emit();
  }
}

class _FakeHistoryRepo implements HistoryRepository {
  final deleted = <({int songId, String? path})>[];

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteHistoryForSong(int songId, String? path) async {
    deleted.add((songId: songId, path: path));
  }

  @override
  Future<void> recordPlay(SongModel song) async {}

  @override
  Stream<List<SongModel>> watchRecentHistory({int limit = 100}) =>
      const Stream<List<SongModel>>.empty();
}

class _FakeLibraryRepo implements LibraryRepository {
  int refreshCount = 0;

  @override
  Future<void> refreshFilters() async => refreshCount++;

  // ---- Kullanılmayan yüzeyler: kasa akışı yalnız refreshFilters'a dokunur.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  late _FakeBannedRepo bannedRepo;
  late _FakeHistoryRepo historyRepo;
  late _FakeLibraryRepo libraryRepo;
  late VaultController vault;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    bannedRepo = _FakeBannedRepo();
    historyRepo = _FakeHistoryRepo();
    libraryRepo = _FakeLibraryRepo();
  });

  tearDown(() {
    Get.reset(); // get 4.7.3'te void döner; beklenemez.
  });

  Future<VaultController> build() async {
    final ctrl = VaultController(bannedRepo, historyRepo, libraryRepo, prefs);
    Get.put<VaultController>(ctrl);
    ctrl.onInit(); // akış aboneliği + güvenlik durumu (void — beklenemez)
    await pumpEventQueue();
    return ctrl;
  }

  group('PIN kilidi', () {
    test('PIN yoksa kurulum gerekir; setPin oturumu açar', () async {
      vault = await build();
      expect(vault.hasPin.value, isFalse);
      expect(vault.isUnlocked.value, isFalse);

      await vault.setPin('1234');
      expect(vault.hasPin.value, isTrue);
      expect(vault.isUnlocked.value, isTrue);
    });

    test('doğru PIN açar, yanlış PIN deneme sayacını işler', () async {
      vault = await build();
      await vault.setPin('1234');
      vault.lock();
      expect(vault.isUnlocked.value, isFalse);

      expect(vault.verifyPin('9999'), isFalse);
      expect(vault.failedAttempts.value, 1);
      expect(vault.verifyPin('1234'), isTrue);
      expect(vault.isUnlocked.value, isTrue);
      expect(vault.failedAttempts.value, 0);
    });

    test('5 hatalı denemeden sonra deneme kilidi başlar', () async {
      vault = await build();
      await vault.setPin('1234');
      vault.lock();

      for (var i = 0; i < 5; i++) {
        expect(vault.verifyPin('0000'), isFalse);
      }
      expect(vault.isLockedOut, isTrue);
      expect(vault.lockoutSecondsLeft, greaterThan(0));

      // Doğru PIN bile kilit süresi bitmeden açmaz.
      expect(vault.verifyPin('1234'), isFalse);
      expect(vault.isUnlocked.value, isFalse);
    });

    test('PIN düz metin saklanmaz; özet SHA-256 hex uzunluğundadır',
        () async {
      vault = await build();
      await vault.setPin('1234');
      final stored = prefs.getString('vault.pin.hash')!;
      expect(stored, isNot(contains('1234')));
      expect(stored.length, 64); // SHA-256 hex
    });
  });

  group('ban / unban', () {
    test('ban: depoya yazar, geçmişi temizler, indeksi yeniler', () async {
      vault = await build();
      final song = _song(1, 'Gizli');

      await vault.ban(song, cleanHistory: true);

      expect(vault.entries, hasLength(1));
      expect(vault.isBanned(song), isTrue);
      expect(historyRepo.deleted.single.songId, 1);
      expect(historyRepo.deleted.single.path, '/music/1.mp3');
      expect(libraryRepo.refreshCount, 1);
    });

    test('cleanHistory=false: geçmişe dokunmaz ama ban geçerli', () async {
      vault = await build();

      await vault.ban(_song(2, 'Geçmiş kalsın'), cleanHistory: false);

      expect(historyRepo.deleted, isEmpty);
      expect(vault.isBanned(_song(2, 'Geçmiş kalsın')), isTrue);
    });

    test('unban: kaydı kaldırır ve indeksi yeniler', () async {
      vault = await build();
      final song = _song(3, 'Geri gelecek');
      await vault.ban(song);
      expect(vault.isBanned(song), isTrue);

      await vault.unban(vault.entries.first);

      expect(vault.isBanned(song), isFalse);
      expect(vault.entries, isEmpty);
      expect(libraryRepo.refreshCount, 2);
    });

    test('akış üzerinden gelen güncelleme kümeleri tazeler', () async {
      vault = await build();
      await bannedRepo.ban(_song(4, 'Akış'));
      await pumpEventQueue();
      expect(vault.isBanned(_song(4, 'Akış')), isTrue);
    });
  });
}
