class AppSettingsModel {
  const AppSettingsModel({required this.languageCode});
  final String languageCode;

  AppSettingsModel copyWith({String? languageCode}) {
    return AppSettingsModel(languageCode: languageCode ?? this.languageCode);
  }
}