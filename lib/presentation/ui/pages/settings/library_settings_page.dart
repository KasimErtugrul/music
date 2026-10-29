import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/pages/settings/excluded_folders_page.dart';

class LibrarySettingsPage extends StatelessWidget {
  const LibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<PreferencesController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLibrary)),
      body: Obx(() {
        final lib = ctrl.library.value;
        return ListView(
          children: [
            SettingsSwitchTile(
              title: l10n.scanOnStartup,
              subtitle: l10n.scanOnStartupHint,
              value: lib.scanOnStartup,
              onChanged: ctrl.setScanOnStartup,
            ),
            SettingsChoiceTile<int>(
              title: l10n.minDuration,
              value: lib.minDurationSeconds,
              options: const [0, 30, 60],
              labelOf: (v) => v == 0 ? 'Yok / None' : '$v s',
              onChanged: (v) {
                ctrl.setMinDuration(v);
                // Ek-A: Filtre anında uygulansın. Repository, değişen filtre
                // değerini görüp sıralı liste önbelleğini geçersiz kılar;
                // liste mevcut indeksten yeniden süzülür (rescan GEREKMEZ).
                Get.find<LibraryController>().reloadSongs();
              },
            ),
              ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(l10n.excludedFolders),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const ExcludedFoldersPage()),
            ),
          ],
        );
      }),
    );
  }
}