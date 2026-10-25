import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSettingsPage extends StatelessWidget {
  const WidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<HomeWidgetController>();

    // Başlangıç değerini oku
    final prefs = Get.find<SharedPreferences>();
    final initialTransparency = prefs.getBool('widget_transparent') ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetSettings)),
      body: ListView(
        children: [
          SettingsSectionHeader(title: l10n.widgetSettings),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.addWidgetHint, style: Theme.of(context).textTheme.bodyMedium),
          ),
          StatefulBuilder(
            builder: (context, setState) {
              return SettingsSwitchTile(
                title: l10n.widgetTransparency,
                subtitle: l10n.widgetTransparencyDesc,
                value: initialTransparency,
                onChanged: (val) async {
                  setState(() {});
                  await ctrl.setTransparency(val);
                },
              );
            }
          ),
        ],
      ),
    );
  }
}