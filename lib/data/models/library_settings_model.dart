class LibrarySettingsModel {
  const LibrarySettingsModel({
    this.scanOnStartup = true,
    this.minDurationSeconds = 0,
  });

  final bool scanOnStartup;
  final int minDurationSeconds;

  LibrarySettingsModel copyWith({
    bool? scanOnStartup,
    int? minDurationSeconds,
  }) {
    return LibrarySettingsModel(
      scanOnStartup: scanOnStartup ?? this.scanOnStartup,
      minDurationSeconds: minDurationSeconds ?? this.minDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'scanOnStartup': scanOnStartup,
    'minDurationSeconds': minDurationSeconds,
  };

  factory LibrarySettingsModel.fromJson(Map<String, dynamic> json) {
    return LibrarySettingsModel(
      scanOnStartup: json['scanOnStartup'] ?? true,
      minDurationSeconds: json['minDurationSeconds'] ?? 0,
    );
  }
}