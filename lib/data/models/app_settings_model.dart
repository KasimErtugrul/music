class AppSettingsModel {
  const AppSettingsModel({
    required this.languageCode,
    required this.themeMode,
    required this.dynamicColor,
    required this.amoledDark,
  });

  final String languageCode;
  final String themeMode;
  final bool dynamicColor;
  final bool amoledDark;

  AppSettingsModel copyWith({
    String? languageCode,
    String? themeMode,
    bool? dynamicColor,
    bool? amoledDark,
  }) {
    return AppSettingsModel(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      amoledDark: amoledDark ?? this.amoledDark,
    );
  }
}