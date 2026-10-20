// Gün 1 güncellik kontrolü. Geliştirme makinesinde çalışır (uygulamanın ağ
// erişimiyle ilgisi yok). Kullanım: dart tool/check_packages.dart
//
// DOĞRULANMADI: pub.dev API alan adları (latest.version, latest.published,
// isDiscontinued, replacedBy; /score içinde tags, likeCount, grantedPoints)
// bu betik yazılırken çalıştırılarak denenmedi. Alan yoksa '?' yazılır.
import 'dart:convert';
import 'dart:io';

const List<String> _packages = <String>[
  // 2-A
  'get', 'just_audio', 'audio_service', 'audio_session', 'rxdart',
  'haudiotagger', 'drift', 'drift_flutter', 'drift_dev', 'build_runner',
  'flex_color_scheme', 'material_color_utilities', 'lrc', 'lyrics_parser',
  'audio_waveforms', 'permission_handler', 'device_info_plus',
  // 2-B (aday, karar kapılı)
  'on_audio_query_pluse', 'dynamic_color',
  // 2-C
  'shared_preferences', 'path_provider', 'file_picker', 'share_plus',
  'home_widget', 'mocktail', 'flutter_launcher_icons', 'flutter_native_splash',
];

Future<Map<String, dynamic>?> _getJson(HttpClient client, String url) async {
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    if (res.statusCode != 200) {
      await res.drain<void>();
      return null;
    }
    final body = await res.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } on Object {
    return null;
  }
}

Future<void> main() async {
  final client = HttpClient();
  final now = DateTime.now().toUtc();
  stdout.writeln('| paket | son sürüm | yayın tarihi | yaş (gün) | android | '
      'beğeni | puan | durum |');
  stdout.writeln('|---|---|---|---|---|---|---|---|');
  for (final name in _packages) {
    final pkg = await _getJson(client, 'https://pub.dev/api/packages/$name');
    if (pkg == null) {
      stdout.writeln('| $name | ? | ? | ? | ? | ? | ? | BULUNAMADI/ERİŞİLEMEDİ |');
      continue;
    }
    final score =
        await _getJson(client, 'https://pub.dev/api/packages/$name/score');
    final latest = (pkg['latest'] as Map<String, dynamic>?) ?? const {};
    final version = latest['version'] ?? '?';
    final publishedRaw = latest['published'] as String?;
    final published = publishedRaw == null ? null : DateTime.tryParse(publishedRaw);
    final age = published == null ? '?' : '${now.difference(published).inDays}';
    final tags = (score?['tags'] as List?)?.cast<String>() ?? const <String>[];
    final android = tags.contains('platform:android') ? 'evet' : 'belirsiz';
    final flags = <String>[];
    if (pkg['isDiscontinued'] == true) {
      flags.add('DISCONTINUED(yerine: ${pkg['replacedBy'] ?? '?'})');
    }
    if (published != null && now.difference(published).inDays > 365) {
      flags.add('>1 yıl eski');
    }
    stdout.writeln('| $name | $version | '
        '${publishedRaw?.substring(0, 10) ?? '?'} | $age | $android | '
        '${score?['likeCount'] ?? '?'} | ${score?['grantedPoints'] ?? '?'} | '
        '${flags.isEmpty ? 'ok' : flags.join(', ')} |');
  }
  client.close();
}
