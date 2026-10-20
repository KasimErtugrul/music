// Gün 2: AndroidManifest.xml'e izinleri ekler (tekrar çalıştırılabilir).
// Kullanım (proje kökünden): dart tool/manifest_tool.dart
import 'dart:io';

/// izin adı -> android:maxSdkVersion (yoksa null)
const Map<String, String?> _permissions = <String, String?>{
  'android.permission.READ_MEDIA_AUDIO': null,
  'android.permission.READ_EXTERNAL_STORAGE': '32',
  'android.permission.POST_NOTIFICATIONS': null,
  'android.permission.FOREGROUND_SERVICE': null,
  'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK': null,
  'android.permission.WAKE_LOCK': null,
};

void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('Manifest bulunamadı: ${file.path} (proje kökünde misin?)');
    exit(1);
  }
  var xml = file.readAsStringSync();
  if (xml.contains('android.permission.INTERNET')) {
    stderr.writeln('Ana manifest INTERNET izni içeriyor; plan gereği '
        'kaldırılmalı. Dosya değiştirilmedi.');
    exit(1);
  }
  final appIndex = xml.indexOf('<application');
  if (appIndex < 0) {
    stderr.writeln('<application> etiketi bulunamadı.');
    exit(1);
  }
  final buffer = StringBuffer();
  _permissions.forEach((name, maxSdk) {
    if (xml.contains('"$name"')) {
      stdout.writeln('zaten var: $name');
      return;
    }
    final max = maxSdk == null ? '' : ' android:maxSdkVersion="$maxSdk"';
    buffer.writeln('    <uses-permission android:name="$name"$max />');
    stdout.writeln('eklendi: $name${maxSdk == null ? '' : ' (max $maxSdk)'}');
  });
  if (buffer.isNotEmpty) {
    final lineStart = xml.lastIndexOf('\n', appIndex) + 1;
    xml = xml.substring(0, lineStart) + buffer.toString() + xml.substring(lineStart);
    file.writeAsStringSync(xml);
  }
}
