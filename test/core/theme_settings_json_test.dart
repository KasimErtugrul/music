import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/theme/app_colors.dart';
import 'package:resonance/core/theme/theme_engine.dart';

/// Gün 3: ThemeSettings.fromJson alan-seviyesi güvenli ayrıştırma ve
/// scheduledDarkEnabled geçiş kuralı testleri.
void main() {
  group('ThemeSettings.fromJson alan-seviyesi güvenlik (Gün 3)', () {
    test('bozuk themeMode/themeSource/listViewMode varsayılana döner', () {
      final s = ThemeSettings.fromJson(const {
        'themeMode': 'Systems', // geçersiz isim (eski kodda byName patlardı)
        'themeSource': 'moon', // beyaz liste dışı
        'listViewMode': 'wallpaper', // beyaz liste dışı
      });
      expect(s.themeMode, ThemeMode.system);
      expect(s.themeSource, 'seed');
      expect(s.listViewMode, 'comfortable');
    });

    test('bozuk tipli seedColor/textScale/density yalnız kendi alanını düşürür', () {
      final s = ThemeSettings.fromJson(const {
        'seedColor': 'kirmizi', // string → varsayılan tohum
        'textScale': 'büyük', // string → 1.0
        'densityX': 'x', // string → 0
        'fontFamily': 'Lato', // sağlam alan KORUNUR (eski kodda hepsi giderdi)
      });
      expect(s.seedColor, AppColors.defaultSeed);
      expect(s.textScale, 1.0);
      expect(s.density, VisualDensity.standard);
      expect(s.fontFamily, 'Lato');
    });

    test('aralık dışı textScale 0.5–2.0 aralığına kırpılır', () {
      expect(ThemeSettings.fromJson(const {'textScale': 5.0}).textScale, 2.0);
      expect(ThemeSettings.fromJson(const {'textScale': 0.1}).textScale, 0.5);
    });

    test('player alt haritası bozuksa varsayılan oynatıcı stili gelir', () {
      final s = ThemeSettings.fromJson(const {'player': 'bozuk'});
      expect(s.player.backgroundStyle, 'solid');
      expect(s.player.artworkShape, 'rounded');
      expect(s.player.seekBarStyle, 'classic');
    });

    test('geçerli JSON int/double karışımıyla da eksiksiz ayrıştırılır', () {
      final s = ThemeSettings.fromJson(const {
        'themeMode': 'dark',
        'themeSource': 'system',
        'seedColor': 0xFF0061A4,
        'amoled': true,
        'densityX': 0, // jsonDecode int üretir
        'densityY': 0.0, // double da kabul edilir
        'textScale': 1.25,
        'listViewMode': 'grid',
        'scheduledDarkStartHour': 22,
      });
      expect(s.themeMode, ThemeMode.dark);
      expect(s.themeSource, 'system');
      expect(s.seedColor, const Color(0xFF0061A4));
      expect(s.amoled, isTrue);
      expect(s.textScale, 1.25);
      expect(s.listViewMode, 'grid');
      expect(s.scheduledDarkStartHour, 22);
    });
  });

  group('scheduledDarkEnabled geçiş kuralı (Gün 3 Karar)', () {
    test('anahtar yok + varsayılan saatler (20:00–07:00) → kapalı', () {
      final s = ThemeSettings.fromJson(const {});
      expect(s.scheduledDarkEnabled, isFalse);
      expect(s.scheduledDarkStartHour, 20);
      expect(s.scheduledDarkEndHour, 7);
    });

    test('anahtar yok + varsayılandan farklı saatler → açık sayılır', () {
      final s = ThemeSettings.fromJson(const {'scheduledDarkStartHour': 22});
      expect(s.scheduledDarkEnabled, isTrue);
      expect(s.scheduledDarkStartHour, 22);
    });

    test('anahtar yok + yalnız dakika farklıysa da açık sayılır', () {
      final s = ThemeSettings.fromJson(const {'scheduledDarkStartMinute': 30});
      expect(s.scheduledDarkEnabled, isTrue);
    });

    test('anahtar varsa açıkça yazılan değer kazanır', () {
      expect(
        ThemeSettings.fromJson(const {
          'scheduledDarkEnabled': false,
          'scheduledDarkStartHour': 23,
        }).scheduledDarkEnabled,
        isFalse,
      );
      expect(
        ThemeSettings.fromJson(const {
          'scheduledDarkEnabled': true,
        }).scheduledDarkEnabled,
        isTrue,
      );
    });

    test('toJson → fromJson turu alanları korur (Gün 3 anahtarı dahil)', () {
      const original = ThemeSettings(
        themeMode: ThemeMode.dark,
        seedColor: Color(0xFF984061),
        amoled: true,
        textScale: 1.15,
        scheduledDarkEnabled: true,
        scheduledDarkStartHour: 23,
        scheduledDarkEndHour: 6,
      );
      final restored = ThemeSettings.fromJson(original.toJson());
      expect(restored.themeMode, original.themeMode);
      expect(restored.seedColor, original.seedColor);
      expect(restored.amoled, original.amoled);
      expect(restored.textScale, original.textScale);
      expect(restored.scheduledDarkEnabled, isTrue);
      expect(restored.scheduledDarkStartHour, 23);
      expect(restored.scheduledDarkEndHour, 6);
    });

    test('varsayılan örneğin JSON turu scheduledDarkEnabled=false korur', () {
      final restored = ThemeSettings.fromJson(const ThemeSettings().toJson());
      expect(restored.scheduledDarkEnabled, isFalse);
    });
  });
}
