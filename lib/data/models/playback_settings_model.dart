class PlaybackSettingsModel {
  const PlaybackSettingsModel({
    this.seekIntervalSeconds = 10,
    this.autoResume = false,
    this.pauseOnHeadphone = true,
    this.defaultShuffle = false,
    this.defaultRepeat = 0, // 0=none, 1=all, 2=one
    this.speed = 1.0,
    this.pitch = 1.0,
    this.gapless = true,
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
  final bool gapless;
  final bool skipSilence;
  final bool replayGain;

  PlaybackSettingsModel copyWith({
    int? seekIntervalSeconds,
    bool? autoResume,
    bool? pauseOnHeadphone,
    bool? defaultShuffle,
    int? defaultRepeat,
    double? speed,
    double? pitch,
    bool? gapless,
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
      gapless: gapless ?? this.gapless,
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
    'gapless': gapless,
    'skipSilence': skipSilence,
    'replayGain': replayGain,
  };

  factory PlaybackSettingsModel.fromJson(Map<String, dynamic> json) {
    return PlaybackSettingsModel(
      seekIntervalSeconds: json['seekIntervalSeconds'] ?? 10,
      autoResume: json['autoResume'] ?? false,
      pauseOnHeadphone: json['pauseOnHeadphone'] ?? true,
      defaultShuffle: json['defaultShuffle'] ?? false,
      defaultRepeat: json['defaultRepeat'] ?? 0,
      speed: (json['speed'] ?? 1.0).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      gapless: json['gapless'] ?? true,
      skipSilence: json['skipSilence'] ?? false,
      replayGain: json['replayGain'] ?? false,
    );
  }
}
