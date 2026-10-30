import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';

class ListStylePage extends StatelessWidget {
  const ListStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeListTitle)),
      body: Obx(() {
        final s = themeCtrl.settings.value;

        return ListView(
          children: <Widget>[
            // Gün 12: kutucuğun başlığı ayarın adıdır (eskiden bir seçenek
            // etiketi olan listViewCompact kullanılıyordu) + alt açıklama.
            SettingsChoiceTile<String>(
              title: l10n.listViewModeTitle,
              subtitle: l10n.listViewModeDesc,
              value: s.listViewMode,
              options: const <String>['compact', 'comfortable', 'grid'],
              labelOf: (v) => switch (v) {
                'compact' => l10n.listViewCompact,
                'grid' => l10n.listViewGrid,
                _ => l10n.listViewComfortable,
              },
              onChanged: themeCtrl.setListViewMode,
            ),
          ],
        );
      }),
    );
  }
}