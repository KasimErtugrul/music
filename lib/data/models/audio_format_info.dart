/// Bir ses dosyasının başlık bilgisinden çıkarılan teknik format bilgisi.
///
/// Aşama 2: Oynatıcı sayfasındaki format rozetini besler
/// (örn. "FLAC · 44.1 kHz · 16 bit" / "MP3 · 44.1 kHz · 320 kbps").
/// Tüm alanlar nullable'dır; rozet yalnızca en az codec bilinen
/// durumlarda gösterilir.
class AudioFormatInfo {
  const AudioFormatInfo({
    required this.codec,
    this.sampleRate,
    this.bitsPerSample,
    this.bitrateKbps,
    this.lossless = false,
  });

  /// Kısa codec etiketi: FLAC, MP3, AAC, ALAC, Opus, Vorbis, WAV...
  final String codec;

  /// Örnekleme hızı (Hz). Null: başlıktan okunamadı.
  final int? sampleRate;

  /// Bit derinliği. Kayıplı codec'lerde (MP3/AAC/Opus/Vorbis) anlam
  /// taşımaz; UI bu durumda göstermez.
  final int? bitsPerSample;

  /// Bit hızı (kbps). Başlıktan okunamazsa controller, dosya boyutu ve
  /// süreden ortalama bit hızını hesaplayıp ekler.
  final int? bitrateKbps;

  /// Kayıpsız codec mi (FLAC/WAV/ALAC)?
  final bool lossless;

  /// Rozet metni. En az iki parça yoksa null döner; tek "FLAC" gibi
  /// çıplak codec etiketi rozet olarak gösterilmez (bilgi değeri düşük).
  String? get label {
    final parts = <String>[codec];
    final sr = sampleRate;
    if (sr != null && sr > 0) parts.add(_kHzLabel(sr));
    final bits = bitsPerSample;
    if (lossless && bits != null && bits > 0) parts.add('$bits bit');
    final br = bitrateKbps;
    if (br != null && br > 0) parts.add('$br kbps');
    return parts.length > 1 ? parts.join(' · ') : null;
  }

  static String _kHzLabel(int hz) {
    final v = hz / 1000.0;
    final s = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return '$s kHz';
  }

  AudioFormatInfo copyWith({
    String? codec,
    int? sampleRate,
    int? bitsPerSample,
    int? bitrateKbps,
    bool? lossless,
  }) =>
      AudioFormatInfo(
        codec: codec ?? this.codec,
        sampleRate: sampleRate ?? this.sampleRate,
        bitsPerSample: bitsPerSample ?? this.bitsPerSample,
        bitrateKbps: bitrateKbps ?? this.bitrateKbps,
        lossless: lossless ?? this.lossless,
      );

  @override
  String toString() => 'AudioFormatInfo(${label ?? codec})';
}
