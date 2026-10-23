class PlaybackSettingsModel {
  const PlaybackSettingsModel({
    this.seekIntervalSeconds = 10,
    this.autoResume = false,
    this.pauseOnHeadphone = true,
    this.defaultShuffle = false,
    this.defaultRepeat = 0, // 0=none, 1=all, 2=one
  });

  final int seekIntervalSeconds;
  final bool autoResume;
  final bool pauseOnHeadphone;
  final bool defaultShuffle;
  final int defaultRepeat;

  PlaybackSettingsModel copyWith({
    int? seekIntervalSeconds,
    bool? autoResume,
    bool? pauseOnHeadphone,
    bool? defaultShuffle,
    int? defaultRepeat,
  }) {
    return PlaybackSettingsModel(
      seekIntervalSeconds: seekIntervalSeconds ?? this.seekIntervalSeconds,
      autoResume: autoResume ?? this.autoResume,
      pauseOnHeadphone: pauseOnHeadphone ?? this.pauseOnHeadphone,
      defaultShuffle: defaultShuffle ?? this.defaultShuffle,
      defaultRepeat: defaultRepeat ?? this.defaultRepeat,
    );
  }

  Map<String, dynamic> toJson() => {
    'seekIntervalSeconds': seekIntervalSeconds,
    'autoResume': autoResume,
    'pauseOnHeadphone': pauseOnHeadphone,
    'defaultShuffle': defaultShuffle,
    'defaultRepeat': defaultRepeat,
  };

  factory PlaybackSettingsModel.fromJson(Map<String, dynamic> json) {
    return PlaybackSettingsModel(
      seekIntervalSeconds: json['seekIntervalSeconds'] ?? 10,
      autoResume: json['autoResume'] ?? false,
      pauseOnHeadphone: json['pauseOnHeadphone'] ?? true,
      defaultShuffle: json['defaultShuffle'] ?? false,
      defaultRepeat: json['defaultRepeat'] ?? 0,
    );
  }
}