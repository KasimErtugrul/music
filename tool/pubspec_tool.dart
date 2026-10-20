// Gün 1 yardımcı aracı. Kullanım (proje kökünden):
//   dart tool/pubspec_tool.dart patch-flutter
//   dart tool/pubspec_tool.dart pin paket1 paket2 ...
import 'dart:io';

const String _flutterBlock = '''
flutter:
  uses-material-design: true
  generate: true

  assets:
    - assets/images/

  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
    - family: RobotoFlex
      fonts:
        - asset: assets/fonts/RobotoFlex-Medium.ttf
          weight: 500
''';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: patch-flutter | pin <paketler...>');
    exit(64);
  }
  switch (args.first) {
    case 'patch-flutter':
      _patchFlutter();
    case 'pin':
      _pin(args.skip(1).toList());
    default:
      stderr.writeln('Bilinmeyen komut: ${args.first}');
      exit(64);
  }
}

void _patchFlutter() {
  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();
  final i = lines.indexOf('flutter:');
  if (i < 0) {
    stderr.writeln('pubspec.yaml içinde üst düzey "flutter:" bulunamadı.');
    exit(1);
  }
  final trailingTopLevel = lines.skip(i + 1).any(
        (l) => l.isNotEmpty && !l.startsWith(' ') && !l.startsWith('#'),
      );
  if (trailingTopLevel) {
    stderr.writeln('"flutter:" bloğundan sonra başka üst düzey anahtar var; '
        'otomatik yama güvenli değil, elle düzenleyin.');
    exit(1);
  }
  final out = <String>[
    ...lines.sublist(0, i),
    ..._flutterBlock.trimRight().split('\n'),
    '',
  ];
  file.writeAsStringSync(out.join('\n'));
  stdout.writeln('flutter: bloğu güncellendi (generate, assets, fontlar).');
}

void _pin(List<String> names) {
  final lock = File('pubspec.lock').readAsStringSync();
  final pubspec = File('pubspec.yaml');
  var spec = pubspec.readAsStringSync();
  for (final name in names) {
    final n = RegExp.escape(name);
    final lockMatch = RegExp(
      '^  $n:\\n(?:    .*\\n)*?    version: "([^"]+)"',
      multiLine: true,
    ).firstMatch(lock);
    if (lockMatch == null) {
      stdout.writeln('ATLANDI (pubspec.lock içinde yok): $name');
      continue;
    }
    final version = lockMatch.group(1)!;
    final lineRe = RegExp('^  $n: .*\$', multiLine: true);
    if (!lineRe.hasMatch(spec)) {
      stdout.writeln('ATLANDI (pubspec.yaml içinde satır yok): $name');
      continue;
    }
    spec = spec.replaceFirst(lineRe, '  $name: $version');
    stdout.writeln('SABİTLENDİ: $name $version');
  }
  pubspec.writeAsStringSync(spec);
}
