// Gün 5 testi: prefs anahtarlarına ham dizgeyle erişim yasağı.
//
// Planın tek doğruluk kaynağı ilkesi (Gün 1): kalıcılık anahtarları
// yalnız SettingsPersistence sabitleri üzerinden kullanılır. Ham dizgeyle
// yazılan/okunan bir anahtar, Gün 10'daki anahtar geçiş fonksiyonundan ve
// yedek kapsam denetiminden sessizce kaçar. Tetikleyici bulgu: widget
// ayar sayfası 'widget_transparent' anahtarını doğrudan okuyordu (Gün 5'te
// HomeWidgetController.transparency getter'ına bağlandı).
//
// Yöntem: lib/ altındaki tüm .dart kaynakları satır satır taranır;
// SharedPreferences tarzı yöntem çağrılarında dizge sabiti anahtar
// görülürse test, konumları listeleyerek kırılır. Üretilen dosyalar
// (.g.dart) kapsam dışıdır; anahtar sabitlerinin TANIMLARI
// (settings_keys.dart / settings_persistence.dart) yöntem çağrısı
// olmadığı için kurala doğal olarak takılmaz.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ içinde prefs anahtarına ham dizgeyle erişen kod yoktur (Gün 5)',
      () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'\b(getBool|getString|getInt|getDouble|setBool|setString|setInt'
      r'|setDouble|remove)\(\s*[\x27\x22]',
    );

    final dir = Directory('lib');
    expect(dir.existsSync(), isTrue,
        reason: 'Test paket kökünden çalışmalı (lib/ bulunamadı)');

    final entities = dir.listSync(recursive: true).whereType<File>().where(
          (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
        );

    for (final file in entities) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason:
            'Prefs anahtarları yalnız SettingsPersistence sabitleriyle '
            'kullanılmalıdır. Ham dizge kullanan satırlar:\n'
            '${offenders.join('\n')}');
  });
}