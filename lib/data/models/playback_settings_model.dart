class PlaybackSettingsModel {
  const PlaybackSettingsModel({
    this.seekIntervalSeconds = 10,
    this.autoResume = false,
    this.pauseOnHeadphone = true,
    this.defaultShuffle = false,
    this.defaultRepeat = 0, // 0=none, 1=all, 2=one
    this.speed = 1.0,
    this.pitch = 1.0,
    this.skipSilence = false,
    this.replayGain = false,
  });

  final int seekIntervalSeconds;
  final bool autoResume;
  final bool pauseOnHeadphone;
  final bool defaultShuffle;
  final int defaultRepeat;
  final double speed;
  final double pitch;
  final bool skipSilence;
  final bool replayGain;

  // Gün 10 notu (Gün 2 bulgusunun ele alınışı): eski sürümlerdeki ölü
  // «gapless» alanı modelden KALDIRILDI — just_audio, setAudioSources ile
  // yüklenen kuyruklarda kesintisiz geçişi zaten sağlar; hiçbir tüketici
  // yoktu (Gün 2), setGapless'in de çağıranı yoktu. Uyumluluk: eski
  // JSON'lardaki 'gapless' anahtarı artık bilinmeyen alan olarak doğal
  // biçimde yok sayılır (fromJson adıyla okur), toJson yazmaz; eski
  // yedeklerin geri yüklenmesi etkilenmez ('playback_settings' yedekte
  // dizge olarak taşınır, ilk yüklemede alan düşer).

  PlaybackSettingsModel copyWith({
    int? seekIntervalSeconds,
    bool? autoResume,
    bool? pauseOnHeadphone,
    bool? defaultShuffle,
    int? defaultRepeat,
    double? speed,
    double? pitch,
    bool? skipSilence,
    bool? replayGain,
  }) {
    return PlaybackSettingsModel(
      seekIntervalSeconds: seekIntervalSeconds ?? this.seekIntervalSeconds,
      autoResume: autoResume ?? this.autoResume,
      pauseOnHeadphone: pauseOnHeadphone ?? this.pauseOnHeadphone,
      defaultShuffle: defaultShuffle ?? this.defaultShuffle,
      defaultRepeat: defaultRepeat ?? this.defaultRepeat,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      skipSilence: skipSilence ?? this.skipSilence,
      replayGain: replayGain ?? this.replayGain,
    );
  }

  Map<String, dynamic> toJson() => {
    'seekIntervalSeconds': seekIntervalSeconds,
    'autoResume': autoResume,
    'pauseOnHeadphone': pauseOnHeadphone,
    'defaultShuffle': defaultShuffle,
    'defaultRepeat': defaultRepeat,
    'speed': speed,
    'pitch': pitch,
    'skipSilence': skipSilence,
    'replayGain': replayGain,
  };

  /// Gün 10: alan-seviyesi güvenli ayrıştırma — Gün 3'te ThemeSettings'e
  /// uygulanan desenin aynısı (GUN1 raporu «Gün 3/10: fromJson
  /// sağlamlaştırma» diye kayıtlıydı). Tek bozuk/eksik alan TÜM çalma
  /// ayarlarını sıfırlamaz (eski kod, tip uyuşmazlığında — ör. string
  /// speed — TypeError fırlatıp PreferencesController catch'ine düşüyor,
  /// bütün ayarlar varsayılana dönüyordu); yalnız o alan varsayılana döner.
  factory PlaybackSettingsModel.fromJson(Map<String, dynamic> json) {
    int intOf(String key, int fallback) {
      final v = json[key];
      return v is int ? v : fallback;
    }

    bool boolOf(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    // num kabul eder (jsonDecode 0.0'ı double, 2'yi int üretir).
    double doubleOf(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    return PlaybackSettingsModel(
      seekIntervalSeconds: intOf('seekIntervalSeconds', 10),
      autoResume: boolOf('autoResume', false),
      pauseOnHeadphone: boolOf('pauseOnHeadphone', true),
      defaultShuffle: boolOf('defaultShuffle', false),
      defaultRepeat: intOf('defaultRepeat', 0),
      speed: doubleOf('speed', 1.0),
      pitch: doubleOf('pitch', 1.0),
      skipSilence: boolOf('skipSilence', false),
      replayGain: boolOf('replayGain', false),
    );
  }
}