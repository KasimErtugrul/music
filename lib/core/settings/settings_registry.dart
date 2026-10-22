import 'package:resonance/core/settings/settings_keys.dart';

enum SettingsGroup { general, appearance }

class SettingsEntry {
  const SettingsEntry({
    required this.key,
    required this.group,
    required this.titleKey,
    this.descriptionKey,
  });

  final String key;
  final SettingsGroup group;
  final String titleKey;
  final String? descriptionKey;
}

abstract final class SettingsRegistry {
  static const List<SettingsEntry> all = <SettingsEntry>[
    SettingsEntry(
      key: SettingsKeys.languageCode,
      group: SettingsGroup.general,
      titleKey: 'settingsLanguage',
    ),
    SettingsEntry(
      key: SettingsKeys.themeMode,
      group: SettingsGroup.appearance,
      titleKey: 'settingsThemeMode',
    ),
    SettingsEntry(
      key: SettingsKeys.dynamicColor,
      group: SettingsGroup.appearance,
      titleKey: 'settingsDynamicColor',
    ),
    SettingsEntry(
      key: SettingsKeys.amoledDark,
      group: SettingsGroup.appearance,
      titleKey: 'settingsAmoledDark',
    ),
  ];

  static SettingsEntry? find(String key) {
    for (final e in all) {
      if (e.key == key) return e;
    }
    return null;
  }

  static List<SettingsEntry> byGroup(SettingsGroup group) =>
      all.where((e) => e.group == group).toList(growable: false);
}