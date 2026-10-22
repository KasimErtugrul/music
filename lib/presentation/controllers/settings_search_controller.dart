import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';

class SettingsSearchController extends GetxController {
  final query = ''.obs;

  List<SettingsEntry> filter(List<SettingsEntry> entries, AppLocalizations l10n) {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return entries;

    return entries.where((e) {
      final title = _titleOf(e, l10n).toLowerCase();
      return title.contains(q);
    }).toList(growable: false);
  }

  String _titleOf(SettingsEntry entry, AppLocalizations l10n) {
    switch (entry.titleKey) {
      case 'settingsLanguage':
        return l10n.settingsLanguage;
      case 'settingsThemeMode':
        return l10n.settingsThemeMode;
      case 'settingsDynamicColor':
        return l10n.settingsDynamicColor;
      case 'settingsAmoledDark':
        return l10n.settingsAmoledDark;
      default:
        return entry.titleKey;
    }
  }
}