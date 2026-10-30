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

  /// Gün 10: alan-seviyesi güvenli ayrıştırma — Gün 3'te ThemeSettings'e
  /// uygulanan desenin aynısı (GUN1 raporu «Gün 3/10: fromJson
  /// sağlamlaştırma» diye kayıtlıydı). Tek bozuk/eksik alan yalnız o
  /// alanı varsayılana döndürür; TÜM kitaplık ayarlarını sıfırlamaz.
  factory LibrarySettingsModel.fromJson(Map<String, dynamic> json) {
    bool boolOf(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    int intOf(String key, int fallback) {
      final v = json[key];
      return v is int ? v : fallback;
    }

    return LibrarySettingsModel(
      scanOnStartup: boolOf('scanOnStartup', true),
      minDurationSeconds: intOf('minDurationSeconds', 0),
    );
  }
}