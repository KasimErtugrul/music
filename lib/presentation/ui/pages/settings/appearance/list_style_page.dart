import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            SettingsGroupCard(children: <Widget>[
              SettingsChoiceTile<String>(
                title: l10n.listViewCompact,
                subtitle: l10n.listViewStyleDesc,
                value: s.listViewMode,
                options: const <String>['compact', 'comfortable', 'grid'],
                labelOf: (v) => switch (v) {
                  'compact' => l10n.listViewCompact,
                  'grid' => l10n.listViewGrid,
                  _ => l10n.listViewComfortable,
                },
                onChanged: themeCtrl.setListViewMode,
              ),
            ]),
          ],
        );
      }),
    );
  }
}
