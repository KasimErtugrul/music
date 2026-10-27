import 'package:get/get.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/l10n/app_localizations_en.dart';
import 'package:resonance/l10n/app_localizations_tr.dart';

/// Görev 4.2: ayar arama motoru.
///
/// Eşleme, geçerli dilin başlığının YANINDA diğer dilin (TR/EN) başlığında
/// da yapılır: Türkçe arayüzde 'headphone' yazıldığında da sonuç döner.
/// Diğer dil, l10n üretiminin bağlam-sız sınıflarından (AppLocalizationsEn /
/// AppLocalizationsTr) alınır; BuildContext gerektirmez ve yalnızca başlık
/// okuması yapıldığı için herhangi bir yönlendirme/overlay kurulumuna
/// ihtiyaç duymaz.
class SettingsSearchController extends GetxController {
  final query = ''.obs;

  List<SettingsEntry> filter(List<SettingsEntry> entries, AppLocalizations l10n) {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return entries;

    final AppLocalizations other;
    if (l10n is AppLocalizationsTr) {
      other = AppLocalizationsEn();
    } else {
      other = AppLocalizationsTr();
    }

    return entries.where((e) {
      final t1 = e.title(l10n).toLowerCase();
      final t2 = e.title(other).toLowerCase();
      return t1.contains(q) || t2.contains(q);
    }).toList(growable: false);
  }
}
