import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget ayarları.
///
/// Görev 1.3: Sayfa StatefulWidget'a çevrildi. Eski StatefulBuilder sürümü
/// [initialTransparency] değişkenini onChanged içinde güncellemediği için
/// anahtar görsel olarak değişmiyordu (setState boş çağrılıyordu). Artık
/// değer [setState] ile yönetilir: anahtar doğru değerle açılır ve
/// dokunulduğunda animasyonla güncellenir.
class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  late bool _transparent;

  @override
  void initState() {
    super.initState();
    _transparent =
        Get.find<SharedPreferences>().getBool('widget_transparent') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<HomeWidgetController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetSettings)),
      body: ListView(
        children: [
          SettingsSectionHeader(title: l10n.widgetSettings),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.addWidgetHint, style: Theme.of(context).textTheme.bodyMedium),
          ),
          SettingsSwitchTile(
            title: l10n.widgetTransparency,
            subtitle: l10n.widgetTransparencyDesc,
            value: _transparent,
            onChanged: (val) {
              // Önce görsel durumu güncelle (Görev 1.3 düzeltmesi),
              // sonra tercihi kalıcılaştır ve widget'ı yeniden boyat.
              setState(() => _transparent = val);
              ctrl.setTransparency(val);
            },
          ),
        ],
      ),
    );
  }
}
