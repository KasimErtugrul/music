import 'dart:async';

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
}
