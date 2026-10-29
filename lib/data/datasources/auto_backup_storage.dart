// Aşama 6: Otomatik yedekleme — dosya katmanı.
//
// Yedekler application documents dizini altındaki 'backups/' klasörüne
// 'resonance_auto_<millis>.json' adıyla yazılır. Listeleme, okuma, silme ve
// saklama politikası (prune) burada toplanır; karar mantığı denetleyicide,
// model üretimi BackupRepository'dedir.
//
// resolveDir enjekte edilebilir: birim testler gerçek geçici dizinle
// path_provider eklentisi OLMADAN çalışır. Tüm metotlar hata fırlatmaz;
// bozuk/eksik dosya null veya sessiz no-op'tur — otomatik yedek, kullanıcı
// akışını asla engellememelidir.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:resonance/data/models/backup_model.dart';

/// Tek otomatik yedek kaydı (dosya üstverisi).
class AutoBackupEntry {
  const AutoBackupEntry({
    required this.fileName,
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String fileName;
  final String path;
  final DateTime createdAt;
  final int sizeBytes;
}

class AutoBackupStorage {
  AutoBackupStorage({Future<Directory> Function()? resolveDir})
      : _resolveDir = resolveDir ?? _defaultDir;

  final Future<Directory> Function() _resolveDir;

  static Future<Directory> _defaultDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/backups');
  }

  /// Dosya adı sözleşmesi: resonance_auto_<millis>.json
  /// millis, yaratma zamanıdır; listede DateTime'a çevrilir.
  static const String filePrefix = 'resonance_auto_';
  static const String fileExt = '.json';
  static final RegExp _nameRegExp = RegExp(r'^resonance_auto_(\d+)\.json$');

  Future<Directory> _ensureDir() async {
    final dir = await _resolveDir();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// En yeniden eskiye doğru sıralı yedek listesi. Yabancı dosyalar ve alt
  /// dizinler yok sayılır (klasöre kullanıcı başka dosya koyabilir).
  Future<List<AutoBackupEntry>> list() async {
    final dir = await _resolveDir();
    if (!await dir.exists()) return const <AutoBackupEntry>[];
    final entries = <AutoBackupEntry>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name =
          entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final m = _nameRegExp.firstMatch(name);
      if (m == null) continue;
      final ms = int.tryParse(m.group(1)!);
      if (ms == null) continue;
      try {
        final stat = await entity.stat();
        entries.add(AutoBackupEntry(
          fileName: name,
          path: entity.path,
          createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
          sizeBytes: stat.size,
        ));
      } on Object {
        // Dosya listeleme ile stat arasında silindiyse yok sayılır.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Yedeği diske yazar ve kaydını döner. Aynı milisaniyede ikinci yazım
  /// (testlerde görülür) ad çakıştırma döngüsüyle çözülür.
  Future<AutoBackupEntry> write(BackupModel model) async {
    final dir = await _ensureDir();
    var ms = DateTime.now().millisecondsSinceEpoch;
    var file = File('${dir.path}/$filePrefix$ms$fileExt');
    while (await file.exists()) {
      ms += 1;
      file = File('${dir.path}/$filePrefix$ms$fileExt');
    }
    await file.writeAsString(jsonEncode(model.toJson()), flush: true);
    return AutoBackupEntry(
      fileName: '$filePrefix$ms$fileExt',
      path: file.path,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
      sizeBytes: await file.length(),
    );
  }

  /// Bozuk/eksik yedek null döner; hata yükseltilmez. Geri yükleme UI'ı
  /// null'u "başarısız" olarak bildirir.
  Future<BackupModel?> read(AutoBackupEntry entry) async {
    try {
      final content = await File(entry.path).readAsString();
      return BackupModel.fromJson(
          jsonDecode(content) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> delete(AutoBackupEntry entry) async {
    try {
      final f = File(entry.path);
      if (await f.exists()) await f.delete();
    } on Object {
      // Silme başarısız olsa da uygulama akışı bozulmaz.
    }
  }

  /// Saklama politikası: en yeni [keepCount] yedek dışındakiler silinir.
  /// Liste en yeniden eskiye sıralı geldiği için budama basittir.
  Future<void> prune(int keepCount) async {
    if (keepCount < 0) keepCount = 0;
    final all = await list();
    for (final e in all.skip(keepCount)) {
      await delete(e);
    }
  }
}
