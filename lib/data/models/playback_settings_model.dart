import 'dart:convert';

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
    this.fadeMs = 0,
    this.gaplessPlayback = true,
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

  /// Gün 20: oynat/duraklat yumuşatma (fade) süresi, milisaniye.
  /// 0 = kapalı (davranış eskisi gibi anlıktır); 250 = kısa, 1000 = uzun.
  /// Depo katmanı (PlayerRepositoryImpl) çalma/duraklatma sırasında sesi
  /// bu süre boyunca kademeli taşır; kullanıcı fade sırasında ses
  /// değiştirirse rampa iptal edilir.
  final int fadeMs;

  /// Bulgu 8: boşluksuz geçiş. Açıkken (varsayılan) AudioPlayer,
  /// `useLazyPreparation: false` ile kurulur: bir sonraki parça ÖNCEDEN
  /// çözülür, parçalar arası yükleme boşluğu kapanır. Kapalıyken motorun
  /// varsayılan tembel hazırlığı kullanılır (düşük donanımda bellek
  /// tasarrufu; geçişte kısa duraksama olabilir). just_audio 0.10'da bu
  /// bayrak oynatıcı KURULUMUNDA sabitlenir (final alan) — değişiklik
  /// uygulamanın SONRAKİ AÇILIŞINDA geçerlidir; ayar balonu bunu söyler.
  final bool gaplessPlayback;

  /// Bulgu 8: oynatıcı kurulurken (main → PlayerDataSource) tercih,
  /// denetleyicinin asenkron yüklemesini beklemeden ham prefs'ten
  /// senkron okunur. Eksik/bozuk JSON → varsayılan (açık).
  static bool gaplessFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return true;
    try {
      final v =
          (jsonDecode(raw) as Map<String, dynamic>)['gaplessPlayback'];
      return v is bool ? v : true;
    } on Object {
      return true;
    }
  }

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
    int? fadeMs,
    bool? gaplessPlayback,
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
      fadeMs: fadeMs ?? this.fadeMs,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
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
    'fadeMs': fadeMs,
    'gaplessPlayback': gaplessPlayback,
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
      fadeMs: intOf('fadeMs', 0),
      // Bulgu 8: eski JSON'larda anahtar yoktur → varsayılan (açık).
      // Eski ölü 'gapless' anahtarıyla ad çakışmaz, göz ardı edilir.
      gaplessPlayback: boolOf('gaplessPlayback', true),
    );
  }
}