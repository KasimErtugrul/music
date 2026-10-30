import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_tile.dart';
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
              subtitle: l10n.minDurationDesc,
              value: lib.minDurationSeconds,
              options: const [0, 30, 60],
              // Gün 12: süre etiketleri l10n (0 = Kapalı; örn. "30 sn").
              labelOf: (v) =>
                  v == 0 ? l10n.minDurationOff : l10n.minDurationSeconds(v),
              onChanged: (v) {
                ctrl.setMinDuration(v);
                // Ek-A: Filtre anında uygulansın. Repository, değişen filtre
                // değerini görüp sıralı liste önbelleğini geçersiz kılar;
                // liste mevcut indeksten yeniden süzülür (rescan GEREKMEZ).
                Get.find<LibraryController>().reloadSongs();
              },
            ),
            // Gün 12: ortak SettingsTile yüzü + alt açıklama.
            SettingsTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: l10n.excludedFolders,
              subtitle: l10n.excludedFoldersDesc,
              onTap: () => Get.to(() => const ExcludedFoldersPage()),
            ),
          ],
        );
      }),
    );
  }
}