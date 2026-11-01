import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/pages/equalizer_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_tile.dart';

/// Gün 20: sayfa artık yalnız ekolayzer girişi değil, ses ayarlarının
/// merkezi: ekolayzer hızlı anahtarı + ekran girişi + oynat/duraklat
/// yumuşatma (fade). Hız/perde oynatıcı sayfasındaki hız-perde alt
/// sayfasında, sessizlik atlama ve ReplayGain çalma ayarlarında yaşar;
/// buraya kopyalanmadı (tek doğruluk kaynağı).
///
/// Ekolayzer anahtarı genel [EqualizerController]'ı kullanır (InitialBinding
/// uygulama açılışında kurar); anahtarın loudness kanalıyla etkileşimi
/// (Görev 2.3 sözleşmesi) controller'daki toggleEnabled ile aynı yoldan
/// geçer — sayfa kendi başına kanal yazmaz.
class AudioSettingsPage extends StatelessWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eqCtrl = Get.find<EqualizerController>();
    final prefCtrl = Get.find<PreferencesController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioSettingsTitle)),
      body: ListView(
        // Gün 12: ortak SettingsTile + grup kartı.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingsSectionHeader(title: l10n.audioGroupEqualizer),
          Obx(() {
            return SettingsGroupCard(children: [
              SettingsSwitchTile(
                title: l10n.equalizerTitle,
                value: eqCtrl.isEnabled.value,
                onChanged: eqCtrl.toggleEnabled,
                info: l10n.eqSwitchInfo,
              ),
              SettingsTile(
                title: l10n.audioEqOpenTitle,
                subtitle: l10n.audioEqOpenDesc,
                leading: const Icon(Icons.equalizer),
                onTap: () => Get.to(() => const EqualizerPage()),
              ),
            ]);
          }),
          SettingsSectionHeader(title: l10n.audioGroupFade),
          Obx(() {
            final p = prefCtrl.playback.value;
            return SettingsGroupCard(children: [
              SettingsChoiceTile<int>(
                title: l10n.fadeTitle,
                value: p.fadeMs,
                options: const [0, 250, 1000],
                labelOf: (v) => switch (v) {
                  250 => l10n.fadeShort,
                  1000 => l10n.fadeLong,
                  _ => l10n.fadeOff,
                },
                onChanged: prefCtrl.setFadeMs,
                info: l10n.fadeInfo,
              ),
            ]);
          }),
        ],
      ),
    );
  }
}