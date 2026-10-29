import 'dart:io';
import 'dart:typed_data';

import 'package:resonance/data/models/audio_format_info.dart';

/// Ses dosyası başlık okuyucu — saf Dart, ek bağımlılık yok.
///
/// Aşama 2: format rozeti için örnekleme hızı / bit derinliği / codec
/// bilgisini dosyanın başlık baytlarından çıkarır. Şarkı başına bir kez
/// çalıştırılır (PlayerController önbellekler); header okuma dışında
/// dosyanın tamamını asla açmaz.
///
/// Desteklenen biçimler:
/// - FLAC  : "fLaC" + STREAMINFO (hız, kanal, bit derinliği)
/// - WAV   : RIFF/WAVE "fmt " chunk (PCM / IEEE float / extensible)
/// - OGG   : ilk sayfa paketi (Vorbis id header / OpusHead)
/// - MP3   : ID3v2 atlama + ilk geçerli MPEG frame başlığı (MP1/2/2.5)
/// - MP4   : kutu gezinmesi → moov → stsd örnekleme girdisi (AAC/ALAC)
///
/// Tanınmayan/bozuk biçimlerde null döner; çağıran taraf uzantıdan codec
/// tahmini ve boyut/süreOranı ile zenginleştirir ([PlayerController]).
class AudioFormatDatasource {
  /// MP3 frame taraması için ilk bakış penceresi (ID3 kapakları büyük
  /// olabilir; 128 KB çoğu dosyada ilk frame'i yakalar).
  static const int _probeBytes = 128 * 1024;

  /// MP4 moov kutusu için okuma sınırı (çok track'li dosyalar nadiren
  /// büyür; kapak verisi moov içinde değildir).
  static const int _moovProbeBytes = 512 * 1024;

  Future<AudioFormatInfo?> read(String path) async {
    if (path.isEmpty) return null;
    RandomAccessFile? raf;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      raf = await file.open();
      final head = await raf.read(16);
      if (head.length < 12) return null;

      if (_ascii(head, 0, 'fLaC')) {
        await raf.setPosition(0);
        return parseFlac(await raf.read(64));
      }
      if (_ascii(head, 0, 'RIFF') && _ascii(head, 8, 'WAVE')) {
        await raf.setPosition(0);
        return parseWav(await raf.read(16 * 1024));
      }
      if (_ascii(head, 0, 'OggS')) {
        await raf.setPosition(0);
        return parseOgg(await raf.read(4096));
      }
      if (_ascii(head, 4, 'ftyp') ||
          _ascii(head, 4, 'moov') ||
          _ascii(head, 4, 'styp')) {
        // await şart: try bloğunda Future await edilmeden dönerse finally
        // hemen çalışıp raf'ı kapatır; _parseMp4 daha dosyayı okurken
        // "file closed" hatası alır ve bu hata catch'e düşmez. await ile
        // önce MP4 parse'ı biter, hata olursa on Object yakalar, en son
        // finally dosyayı kapatır.
        return await _parseMp4(raf, await file.length());
      }
      // Kalanlar (mp3, aac adts, mp2...) frame taramasına girer.
      await raf.setPosition(0);
      return parseMp3(await raf.read(_probeBytes));
    } on Object {
      return null;
    } finally {
      try {
        await raf?.close();
      } on Object {
        // Kapatma hataları akışı etkilemez.
      }
    }
  }

  // ============ FLAC ============

  /// "fLaC" + ilk metadata bloğu (STREAMINFO, tip 0) bekler.
  static AudioFormatInfo? parseFlac(Uint8List b) {
    if (b.length < 8 + 34) return null;
    if (!_ascii(b, 0, 'fLaC')) return null;
    final blockType = b[4] & 0x7F;
    final blockLen = (b[5] << 16) | (b[6] << 8) | b[7];
    if (blockType != 0 || blockLen < 34) return null;

    final d = 8; // STREAMINFO veri başlangıcı
    final sampleRate = (b[d + 10] << 12) | (b[d + 11] << 4) | (b[d + 12] >> 4);
    final channels = ((b[d + 12] >> 1) & 0x07) + 1;
    final bits = (((b[d + 12] & 0x01) << 4) | (b[d + 13] >> 4)) + 1;
    if (sampleRate == 0 || channels == 0 || bits < 4) return null;
    return AudioFormatInfo(
      codec: 'FLAC',
      sampleRate: sampleRate,
      bitsPerSample: bits,
      lossless: true,
    );
  }

  // ============ WAV ============

  /// RIFF/WAVE + "fmt " chunk. PCM(1), IEEE float(3), extensible(0xFFFE)
  /// desteklenir; extensible'da gerçek biçim SubFormat GUID'inin ilk
  /// 2 baytından okunur.
  static AudioFormatInfo? parseWav(Uint8List b) {
    if (b.length < 44) return null;
    if (!_ascii(b, 0, 'RIFF') || !_ascii(b, 8, 'WAVE')) return null;
    var pos = 12;
    while (pos + 8 <= b.length) {
      final id = _fourcc(b, pos);
      final size = _le32(b, pos + 4);
      if (id == 'fmt ') {
        if (pos + 8 + 16 > b.length) return null;
        final fmt = _le16(b, pos + 8);
        final sampleRate = _le32(b, pos + 12);
        final bits = _le16(b, pos + 22);
        var codec = 'WAV';
        var lossless = false;
        var effective = fmt;
        if (fmt == 0xFFFE && pos + 8 + 40 <= b.length) {
          effective = _le16(b, pos + 8 + 24);
        }
        if (effective == 1) {
          lossless = true;
        } else if (effective == 3) {
          codec = 'WAV Float';
          lossless = true;
        }
        if (sampleRate <= 0) return null;
        return AudioFormatInfo(
          codec: codec,
          sampleRate: sampleRate,
          bitsPerSample: lossless && bits > 0 ? bits : null,
          lossless: lossless,
        );
      }
      if (size <= 0) return null;
      pos += 8 + size + (size & 1); // chunk'lar 2 bayt hizalıdır
    }
    return null;
  }

  // ============ OGG ============

  /// İlk sayfanın ilk paketi: Vorbis id header veya OpusHead.
  /// Opus çıktı hızı her zaman 48 kHz'dir; header'daki giriş hızı gösterilir.
  ///
  /// Alt sınır 27 bayt: sayfa başlığı tam olarak budur. Gerçek Opus ilk
  /// sayfası 47 bayt (27 + 1 + 19), Vorbis 58 bayttır; daha yüksek bir
  /// alt sınır minimal tamponları reddedip Opus/Vorbis rozetini boşa
  /// çıkarır (test tam bu durumu yakaladı).
  static AudioFormatInfo? parseOgg(Uint8List b) {
    if (b.length < 27) return null;
    if (!_ascii(b, 0, 'OggS')) return null;
    final segs = b[26];
    final data = 27 + segs; // segment tablosundan hemen sonra paket verisi
    // Paket başından 16 bayt okunabilmeli (Vorbis id hız alanı data+12'de,
    // OpusHead giriş hızı da data+12'de; son okunan bayt data+15).
    if (data + 16 > b.length) return null;

    if (b[data] == 0x01 && _ascii(b, data + 1, 'vorbis')) {
      final sampleRate = _le32(b, data + 12);
      return AudioFormatInfo(
        codec: 'Vorbis',
        sampleRate: sampleRate > 0 ? sampleRate : null,
        lossless: false,
      );
    }
    if (_ascii(b, data, 'OpusHead')) {
      final inputRate = _le32(b, data + 12);
      return AudioFormatInfo(
        codec: 'Opus',
        sampleRate: inputRate > 0 ? inputRate : 48000,
        lossless: false,
      );
    }
    return null;
  }

  // ============ MP3 / MPEG audio ============

  // Bit hızı tabloları (kbps) — MPEG 1/2(+2.5) ve katmanlara göre.
  static const List<int> _mp1l1 = [
    0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,
  ];
  static const List<int> _mp1l2 = [
    0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384,
  ];
  static const List<int> _mp1l3 = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320,
  ];
  static const List<int> _mp2l1 = [
    0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256,
  ];
  static const List<int> _mp2l2 = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160,
  ];
  static const List<int> _mp2l3 = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160,
  ];

  /// ID3v2 etiketini atlayıp ilk geçerli MPEG frame başlığını tarar.
  /// Kayıplı olduğundan bit derinliği döndürülmez.
  static AudioFormatInfo? parseMp3(Uint8List b) {
    if (b.length < 16) return null;
    var off = 0;
    if (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
      final size = ((b[6] & 0x7F) << 21) |
          ((b[7] & 0x7F) << 14) |
          ((b[8] & 0x7F) << 7) |
          (b[9] & 0x7F);
      off = 10 + size;
    }
    for (var i = off; i < b.length - 4; i++) {
      if (b[i] != 0xFF || (b[i + 1] & 0xE0) != 0xE0) continue;
      final b1 = b[i + 1];
      final b2 = b[i + 2];
      final verBits = (b1 >> 3) & 0x03; // 0=MPEG2.5, 2=MPEG2, 3=MPEG1
      final layerBits = (b1 >> 1) & 0x03; // 1=III, 2=II, 3=I
      if (verBits == 1 || layerBits == 0) continue;
      final brIdx = (b2 >> 4) & 0x0F;
      final srIdx = (b2 >> 2) & 0x03;
      if (brIdx == 0 || brIdx == 15 || srIdx == 3) continue;

      const sampleRates = <int, List<int>>{
        3: [44100, 48000, 32000],
        2: [22050, 24000, 16000],
        0: [11025, 12000, 8000],
      };
      final sampleRate = sampleRates[verBits]![srIdx];

      final List<int> table;
      switch (layerBits) {
        case 1:
          table = verBits == 3 ? _mp1l3 : _mp2l3;
        case 2:
          table = verBits == 3 ? _mp1l2 : _mp2l2;
        default:
          table = verBits == 3 ? _mp1l1 : _mp2l1;
      }
      final kbps = table[brIdx];
      final codec = layerBits == 1 ? 'MP3' : (layerBits == 2 ? 'MP2' : 'MP1');
      return AudioFormatInfo(
        codec: codec,
        sampleRate: sampleRate,
        bitrateKbps: kbps > 0 ? kbps : null,
        lossless: false,
      );
    }
    return null;
  }

  // ============ MP4 / M4A ============

  /// Üst düzey kutuları gezerek moov'u bulur; moov içinde stsd'yi arar.
  /// 64-bit kutu boyutları (size==1) desteklenir.
  Future<AudioFormatInfo?> _parseMp4(RandomAccessFile raf, int fileSize) async {
    var pos = 0;
    for (var i = 0; i < 64 && pos + 8 <= fileSize; i++) {
      final hdr = await _readAt(raf, pos, 8);
      if (hdr.length < 8) return null;
      var size = _be32(hdr, 0);
      final type = _fourcc(hdr, 4);
      if (size == 1) {
        final ext = await _readAt(raf, pos + 8, 8);
        if (ext.length < 8) return null;
        size = _be64(ext, 0);
      } else if (size == 0) {
        size = fileSize - pos; // dosya sonuna kadar uzanır
      }
      if (size < 8) return null;
      if (type == 'moov') {
        final readLen = size > _moovProbeBytes ? _moovProbeBytes : size;
        final moov = await _readAt(raf, pos, readLen);
        return _findStsd(moov);
      }
      pos += size;
    }
    return null;
  }

  /// Buffer içinde kutu ağacında dolaşır; ilk stsd'nin örnekleme
  /// girdisini çözümler. Konteyner tiplerinde gövdeye iner.
  static AudioFormatInfo? _findStsd(Uint8List b) {
    const containers = {'moov', 'trak', 'mdia', 'minf', 'stbl'};
    AudioFormatInfo? walk(int start, int end, int depth) {
      if (depth > 6) return null;
      var pos = start;
      while (pos + 8 <= end) {
        var size = _be32(b, pos);
        final type = _fourcc(b, pos + 4);
        if (size == 0) size = end - pos;
        if (size < 8) return null;
        final bodyEnd = pos + size > end ? end : pos + size;
        if (type == 'stsd') {
          return _parseStsd(b, pos, bodyEnd);
        }
        if (containers.contains(type)) {
          final found = walk(pos + 8, bodyEnd, depth + 1);
          if (found != null) return found;
        }
        pos += size;
      }
      return null;
    }

    return walk(0, b.length, 0);
  }

  /// stsd gövdesi: version+flags(4) + entryCount(4) + örnek girdisi.
  /// Ses örnekleme girdisi: format 4cc + reserved(6) + dataRef(2) +
  /// reserved(8) + channels(2) + sampleSize(2) + ... + sampleRate(4, 16.16).
  static AudioFormatInfo? _parseStsd(Uint8List b, int boxStart, int boxEnd) {
    final entryStart = boxStart + 16; // stsd başlığı atlanır
    if (entryStart + 36 > boxEnd) return null;
    final format = _fourcc(b, entryStart + 4);
    if (format.isEmpty) return null;

    final base = entryStart; // girdi kutusunun başı
    final sampleRate = _be32(b, base + 32) >> 16;
    final sampleSize = _le16(b, base + 26);

    switch (format) {
      case 'mp4a':
        // AAC ailesi; kayıplı → bit derinliği anlamsız.
        return AudioFormatInfo(
          codec: 'AAC',
          sampleRate: sampleRate > 0 ? sampleRate : null,
          lossless: false,
        );
      case 'alac':
        return AudioFormatInfo(
          codec: 'ALAC',
          sampleRate: sampleRate > 0 ? sampleRate : null,
          bitsPerSample: sampleSize > 0 ? sampleSize : null,
          lossless: true,
        );
      case 'ac-3':
      case 'ec-3':
        return AudioFormatInfo(
          codec: format == 'ac-3' ? 'AC-3' : 'E-AC-3',
          sampleRate: sampleRate > 0 ? sampleRate : null,
          lossless: false,
        );
      default:
        return AudioFormatInfo(
          codec: format.toUpperCase(),
          sampleRate: sampleRate > 0 ? sampleRate : null,
          lossless: false,
        );
    }
  }

  // ============ Yardımcılar ============

  static Future<Uint8List> _readAt(
    RandomAccessFile raf,
    int pos,
    int len,
  ) async {
    await raf.setPosition(pos);
    return raf.read(len);
  }

  /// [off] itibarıyla [text] ASCII dizisiyle birebir eşleşir mi?
  static bool _ascii(Uint8List b, int off, String text) {
    if (off + text.length > b.length) return false;
    for (var i = 0; i < text.length; i++) {
      if (b[off + i] != text.codeUnitAt(i)) return false;
    }
    return true;
  }

  static String _fourcc(Uint8List b, int off) {
    if (off + 4 > b.length) return '';
    final sb = StringBuffer();
    for (var i = 0; i < 4; i++) {
      final c = b[off + i];
      sb.writeCharCode(c >= 0x20 && c < 0x7F ? c : 0x20);
    }
    return sb.toString();
  }

  static int _le16(Uint8List b, int off) => b[off] | (b[off + 1] << 8);

  static int _le32(Uint8List b, int off) =>
      b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

  static int _be32(Uint8List b, int off) =>
      (b[off] << 24) | (b[off + 1] << 16) | (b[off + 2] << 8) | b[off + 3];

  static int _be64(Uint8List b, int off) {
    var v = 0;
    for (var i = 0; i < 8; i++) {
      v = (v << 8) | b[off + i];
    }
    return v;
  }
}
