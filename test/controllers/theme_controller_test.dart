import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class _MockThemeRepository extends Mock implements ThemeRepository {}

class _MockLibraryRepository extends Mock implements LibraryRepository {}

/// Bulgu 4 testleri için 1x1 düz kırmızı PNG (ek bağımlılık yok):
/// ColorScheme.fromImageProvider bu baytları çözer ve baskın rengi
/// kırmızı bir palet üretir; varsayılan seed (0xFF6750A4, mor) ile
/// kesin ayrışır.
int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b & 0xFF;
    for (var i = 0; i < 8; i++) {
      final mask = -(crc & 1);
      crc = (crc >>> 1) ^ (0xEDB88320 & mask);
    }
  }
  return (~crc) & 0xFFFFFFFF;
}

List<int> _pngChunk(String type, List<int> data) {
  final body = <int>[...type.codeUnits, ...data];
  final crc = _crc32(body);
  final len = data.length;
  return <int>[
    (len >> 24) & 0xFF, (len >> 16) & 0xFF, (len >> 8) & 0xFF, len & 0xFF,
    ...body,
    (crc >> 24) & 0xFF, (crc >> 16) & 0xFF, (crc >> 8) & 0xFF, crc & 0xFF,
  ];
}

Uint8List _solidRedPng() {
  final ihdr = <int>[
    0, 0, 0, 1, // genişlik: 1
    0, 0, 0, 1, // yükseklik: 1
    8, // bit derinliği
    6, // renk tipi: RGBA
    0, 0, 0, // sıkıştırma, filtre, interlace
  ];
  final raw = <int>[0, 255, 0, 0, 255]; // filtre 0 + kırmızı RGBA
  final idat = ZLibEncoder().convert(raw);
  return Uint8List.fromList(<int>[
    137, 80, 78, 71, 13, 10, 26, 10, // PNG imzası
    ..._pngChunk('IHDR', ihdr),
    ..._pngChunk('IDAT', idat),
    ..._pngChunk('IEND', const <int>[]),
  ]);
}

/// Gün 3: özel tema uygulaması (yalnız renk/şekil), yazı ölçeği
/// önizleme/kalıcılık ayrımı, _update kaynak karşılaştırması ve
/// zamanlanmış koyu mod anahtarı testleri.
void main() {
  late _MockThemeRepository repo;
  late _MockLibraryRepository libRepo;
  late StreamController<MediaItem?> playerStream;
  late ThemeController controller;

  setUpAll(() {
    registerFallbackValue(const ThemeSettings());
  });

  setUp(() {
    Get.testMode = true;
    repo = _MockThemeRepository();
    libRepo = _MockLibraryRepository();
    when(() => repo.loadActiveTheme()).thenAnswer((_) async => null);
    when(() => repo.saveActiveTheme(any())).thenAnswer((_) async {});
    when(() => libRepo.artwork(any())).thenAnswer((_) async => null);

    playerStream = StreamController<MediaItem?>();
    controller = ThemeController(repo, playerStream.stream, libRepo);
    controller.onInit();
  });

  tearDown(() {
    // Periodik zamanlayıcıyı iptal etmezsek flutter_test "pending timer" hatası verir.
    controller.dispose();
    playerStream.close();
    Get.reset();
  });

  group('Gün 3: applyCustomTheme (Karar: yalnız renk/şekil)', () {
    test('renk ve şekil alanları uygulanır', () {
      const custom = ThemeSettings(
        seedColor: Color(0xFF0061A4),
        amoled: true,
        highContrast: true,
        surfaceTint: false,
        roundedCorners: false,
        density: VisualDensity.compact,
      );

      controller.applyCustomTheme(custom);

      final s = controller.settings.value;
      expect(s.seedColor, const Color(0xFF0061A4));
      expect(s.amoled, isTrue);
      expect(s.highContrast, isTrue);
      expect(s.surfaceTint, isFalse);
      expect(s.roundedCorners, isFalse);
      expect(s.density, VisualDensity.compact);
    });

    test('kullanıcıya özgü tercihler (mod/kaynak/ölçek/liste) korunur', () {
      const custom = ThemeSettings(
        themeMode: ThemeMode.dark,
        themeSource: 'artwork',
        textScale: 1.3,
        listViewMode: 'grid',
      );

      controller.applyCustomTheme(custom);

      final s = controller.settings.value;
      expect(s.themeMode, ThemeMode.system);
      expect(s.themeSource, 'seed');
      expect(s.textScale, 1.0);
      expect(s.listViewMode, 'comfortable');
    });
  });

  group('Gün 3: yazı ölçeği önizleme/kalıcılık ayrımı', () {
    test('previewTextScale diske yazmaz; commitTextScale tek kez yazar', () async {
      clearInteractions(repo);

      controller.previewTextScale(1.2);
      expect(controller.settings.value.textScale, 1.2);
      verifyNever(() => repo.saveActiveTheme(any()));

      await controller.commitTextScale();
      verify(() => repo.saveActiveTheme(any())).called(1);
    });

    test('commit, önizlenen değeri diske yazar', () async {
      ThemeSettings? saved;
      when(() => repo.saveActiveTheme(any())).thenAnswer((inv) async {
        saved = inv.positionalArguments[0] as ThemeSettings;
      });

      controller.previewTextScale(1.1);
      await controller.commitTextScale();

      expect(saved?.textScale, 1.1);
    });
  });

  group('Gün 3: _update önce/sonra karşılaştırması', () {
    test('kaynak aynıyken başka alan değişimi kapak/şema yeniden okumaz', () async {
      playerStream.add(const MediaItem(
        id: 'content://media/external/audio/media/7',
        title: 'X',
      ));
      await Future<void>.delayed(Duration.zero);

      // Kaynağı artwork yap → bir kez okuma beklenir.
      controller.setThemeSource('artwork');
      await Future<void>.delayed(Duration.zero);
      verify(() => libRepo.artwork(7)).called(1);

      // Kaynak DEĞİŞMEDEN başka alan değiştir → yeni okuma olmamalı.
      clearInteractions(libRepo);
      controller.setAmoled(true);
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => libRepo.artwork(any()));
    });
  });

  group('Gün 3: zamanlanmış koyu mod anahtarı', () {
    test('kapalıyken mod saatten bağımsız system kalır', () {
      controller.setScheduledDarkEnabled(false);
      expect(controller.themeMode, ThemeMode.system);
    });
  });

  group('Bulgu 4: kapak-teması bayatlık kilidi', () {
    final seedPrimary = const Color(0xFF6750A4); // AppColors.defaultSeed
    late Completer<Uint8List?> gateA;
    late Completer<Uint8List?> gateB;

    setUp(() {
      gateA = Completer<Uint8List?>();
      gateB = Completer<Uint8List?>();
      when(() => libRepo.artwork(any())).thenAnswer((inv) {
        final id = inv.positionalArguments[0] as int;
        // Okumalar kapıya takılır: tamamlanma sırası testte kontrol edilir.
        return switch (id) {
          101 => gateA.future,
          102 => gateB.future,
          _ => Future<Uint8List?>.value(null),
        };
      });
    });

    Future<void> pump({int ms = 80}) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    /// Kontrol testi için: kapak okumasından palet yazımına kadar PNG
    /// çözme + niceleme + ton paleti zinciri (ColorScheme.fromImageProvider)
    /// GERÇEK async iş yapar; süresi ilk çağrıda codec/JIT ısınmasına göre
    /// makineden makineye değişir (ölçüm: soğuk ~76 ms, ılık ~0 ms).
    /// Sabit uyku bu süreyi varsaydığından yavaş makinelerde yazım
    /// assertion'dan SONRA gelir ve test haksızca fail olur; bunun yerine
    /// yazım GÖRÜLENE kadar üst sınırlı beklenir.
    Future<void> pumpUntilPaletteChanges(Color from, {int maxMs = 10000}) async {
      final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
      while (DateTime.now().isBefore(deadline) &&
          controller.lightTheme().colorScheme.primary == from) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    const itemA = MediaItem(
      id: 'content://media/external/audio/media/101',
      title: 'A',
    );
    const itemB = MediaItem(
      id: 'content://media/external/audio/media/102',
      title: 'B',
    );

    /// Ortak kurgu: parça A çalıyor, kullanıcı kaynağı «kapak»a alır,
    /// A'nın kapak okuması kapıda askıdadır.
    Future<Color> startPendingArtworkRead() async {
      playerStream.add(itemA);
      await pump(ms: 1);
      controller.setThemeSource('artwork');
      await pump(ms: 1);
      verify(() => libRepo.artwork(101)).called(1);
      // Okuma askıdayken tema hâlâ seed palettedir.
      return controller.lightTheme().colorScheme.primary;
    }

    test('kontrol: güncel parçanın paleti yazılır (kilit testi doğrulanır)',
        () async {
      final before = await startPendingArtworkRead();
      expect(before, seedPrimary);

      gateA.complete(_solidRedPng()); // A hâlâ güncel parça
      await pumpUntilPaletteChanges(seedPrimary);

      // Köprü çalışır: kırmızı kapak paleti tema primary'sine yansır.
      expect(
        controller.lightTheme().colorScheme.primary,
        isNot(seedPrimary),
        reason: 'Kapak paleti yazılmadı: ya yazım 10 sn içinde gelmedi '
            'ya da ColorScheme.fromImageProvider bu ortamda istisna atıp '
            'fromArtwork sessizce null döndürdü (binding/codec denetimi '
            'gerekir).',
      );
    });

    test('kapak okuması sürerken parça değişirse eski palet YAZILMAZ',
        () async {
      await startPendingArtworkRead();

      // Hızlı geçiş: parça B; onun okuması null kapakla hemen biter.
      gateB.complete(null);
      playerStream.add(itemB);
      await pump(ms: 1);

      // ŞİMDİ A'nın ağır okuması tamamlanır — bu arada parça değişti.
      gateA.complete(_solidRedPng());
      // Bayat yazım YOK sözleşmesi: kilit doğruysa hiçbir zaman yazılmaz.
      // Pencere, yavaş makinelerde de hipotetik bozuk yazımın
      // YAKALANABİLECEĞİ genişlikte sabit tutulur (soğuk palet hesabı
      // ~76 ms ölçüldü).
      await pump(ms: 300);

      // Kilit: A'nın paleti yazılmaz; tema seed'te takılı kalmaz.
      expect(controller.lightTheme().colorScheme.primary, seedPrimary);
    });

    test('kaynak seed\'e dönerse bekleyen kapak okuması YAZAMAZ', () async {
      await startPendingArtworkRead();

      // Kullanıcı kaynağı seed'e çevirir: _update kanalları sıfırlar.
      controller.setThemeSource('seed');
      await pump(ms: 1);

      // A'nın okuması geç tamamlanır — kaynak artık kapak değil.
      gateA.complete(_solidRedPng());
      // Kilit sözleşmesi: geniş pencerede de yazım olmamalı (bkz. üstte).
      await pump(ms: 300);

      // Kilit: bayat kapak paleti seed temasının üstüne yazılamaz.
      expect(controller.lightTheme().colorScheme.primary, seedPrimary);
    });
  });

  group('Bulgu 4: Material You sorgusu bayatlık kilidi', () {
    final seedPrimary = const Color(0xFF6750A4);
    const redSchemes = (
      light: ColorScheme.light(primary: Color(0xFFFF0000)),
      dark: ColorScheme.dark(primary: Color(0xFFFF0000)),
    );

    test(
        'sorgu sürerken kaynak değişirse şema kanalları DOLDURULMAZ '
        '(kontrol: güncel sorgu uygulanır)', () async {
      final gate = Completer<({ColorScheme light, ColorScheme dark})?>();
      // playerStream tek-aboneliklidir; ikinci controller ayrı kanal alır.
      final sysStream = StreamController<MediaItem?>();
      addTearDown(sysStream.close);
      final sysCtrl = ThemeController(
        repo,
        sysStream.stream,
        libRepo,
        systemSchemeLoader: () => gate.future,
      );
      addTearDown(sysCtrl.dispose);
      sysCtrl.onInit();
      await Future<void>.delayed(Duration.zero);

      // Kaynak «sistem»: sorgu kapıya takılır.
      sysCtrl.setThemeSource('system');
      await Future<void>.delayed(Duration.zero);
      expect(sysCtrl.lightTheme().colorScheme.primary, seedPrimary);

      // KONTROL: sorgu güncenken tamamlanırsa kırmızı şema uygulanır.
      gate.complete(redSchemes);
      await Future<void>.delayed(Duration.zero);
      expect(
        sysCtrl.lightTheme().colorScheme.primary,
        const Color(0xFFFF0000),
      );
    });

    test('sorgu sürerken kaynak seed\'e dönerse kanallar doldurulmaz',
        () async {
      final gate = Completer<({ColorScheme light, ColorScheme dark})?>();
      // playerStream tek-aboneliklidir; ikinci controller ayrı kanal alır.
      final sysStream = StreamController<MediaItem?>();
      addTearDown(sysStream.close);
      final sysCtrl = ThemeController(
        repo,
        sysStream.stream,
        libRepo,
        systemSchemeLoader: () => gate.future,
      );
      addTearDown(sysCtrl.dispose);
      sysCtrl.onInit();
      await Future<void>.delayed(Duration.zero);

      sysCtrl.setThemeSource('system');
      await Future<void>.delayed(Duration.zero);
      sysCtrl.setThemeSource('seed'); // _update kanalları sıfırladı

      // Sorgu geç tamamlanır — kaynak artık sistem değil.
      gate.complete(redSchemes);
      await Future<void>.delayed(Duration.zero);

      // Kilit: bayat Material You paleti seed temasına yazılamaz.
      expect(sysCtrl.lightTheme().colorScheme.primary, seedPrimary);
    });
  });
}
