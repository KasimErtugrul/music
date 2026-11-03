import 'package:get/get.dart';
import 'package:resonance/data/datasources/local/daos/lyrics_dao.dart';

/// Bulgu 6: şarkı sözü sistemi. Veri katmanı (Lyrics tablosu + LyricsDao,
/// şema v9) hazırdı; bu denetleyici onu uygulamaya bağlar.
///
/// * [bySong]: oturum içi önbellek — songId → söz metni. Kartlarda
///   «sözü var» rozeti istenirse aynı harita okunur.
/// * Kaynak: kullanıcı elle yazdığı için `manual`; ileride gömülü etiket
///   okuma eklenirse `embedded` kaynağı aynı tabloya yazılır.
/// * LRC desteği görüntüleyicide.yoktur; burada yalnız metin taşınır —
///   `[mm:ss.xx]` satırları içerikte kaldığı sürece görüntüleyici
///   eşzamanlı modu kendiliğinden seçer.
class LyricsController extends GetxController {
  LyricsController(this._dao);

  final LyricsDao _dao;

  final bySong = RxMap<int, String>();

  /// Şarkının sözü varsa metni; önbellekte yoksa null döner.
  /// (Görüntüleyici açılışında [loadFor] ile tazelenir.)
  String? contentOf(int songId) => bySong[songId];

  /// Şarkının sözünü önbelleğe ve döndürülecek değere yükler.
  Future<String?> loadFor(int songId) async {
    final row = await _dao.get(songId);
    final content = row?.content;
    if (content == null) {
      bySong.remove(songId);
    } else {
      bySong[songId] = content;
    }
    return content;
  }

  /// Sözü kaydeder (upsert) ve önbelleği güncel tutar.
  Future<void> save(int songId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      await remove(songId);
      return;
    }
    await _dao.upsert(songId, trimmed, source: 'manual');
    bySong[songId] = trimmed;
  }

  /// Sözü siler; önbellekten de düşer.
  Future<void> remove(int songId) async {
    await _dao.deleteFor(songId);
    bySong.remove(songId);
  }

  /// İçerik LRC biçiminde mi? (satır başı [mm:ss] ya da satır içi zaman
  /// etiketi). Görüntüleyici eşzamanlı vurguyu bu sinyalle seçer.
  static final RegExp _lrcTag = RegExp(r'\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\]');

  static bool looksLikeLrc(String content) {
    var hits = 0;
    for (final line in content.split('\n')) {
      if (_lrcTag.hasMatch(line)) hits++;
      if (hits >= 2) return true;
    }
    return false;
  }
}
