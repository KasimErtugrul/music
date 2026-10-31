import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_page_reset_action.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';

/// Gün 13: sayfa üç bölüme ayrıldı — «Denetim · Başlangıç davranışı ·
/// Ses işleme». Gruplama oynatma mantığını izler: sarma/kulaklık davranışı
/// çalışı denetler; varsayılanlar yalnız yeni kuyruk başlarken uygulanır
/// (Gün 2 Kararı) ve açılışta devam eder; sessizlik atlamayla ReplayGain
/// ses işleme katmanıdır. AppBar'daki «Bu sayfayı varsayılana döndür»
/// eylemi yalnız bu sayfadaki anahtarları sıfırlar (hız/perde korunur).
///
/// Gün 16: sayfadaki yedi ayar da uygulamaya özeldir (sarma adımı, kulaklık
/// davranışı, oturum devamı, yeni kuyruk varsayılanları, sessizlik atlama,
/// ReplayGain) — hepsine ne işe yaradığını anlatan bilgi balonu bağlandı;
/// metinler ARB'de `xxxInfo` anahtarlarıdır.
class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<PreferencesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPlayback),
        actions: [
          SettingsPageResetAction(onReset: ctrl.resetPlayback),
        ],
      ),
      body: Obx(() {
        final p = ctrl.playback.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // --- Denetim: çalış sırasında dokunarak kullanılan davranışlar ---
            SettingsSectionHeader(title: l10n.playbackGroupControls),
            SettingsGroupCard(children: [
              SettingsChoiceTile<int>(
                title: l10n.seekInterval,
                subtitle: l10n.seekIntervalDesc,
                value: p.seekIntervalSeconds,
                options: const [5, 10, 15, 30],
                labelOf: (v) => l10n.seekIntervalValue(v),
                onChanged: ctrl.setSeekInterval,
                info: l10n.seekIntervalInfo,
              ),
              SettingsSwitchTile(
                title: l10n.pauseOnHeadphone,
                subtitle: l10n.pauseOnHeadphoneDesc,
                value: p.pauseOnHeadphone,
                onChanged: ctrl.setPauseOnHeadphone,
                info: l10n.pauseOnHeadphoneInfo,
              ),
            ]),

            // --- Başlangıç davranışı: açılış ve yeni kuyruk başlarken ---
            SettingsSectionHeader(title: l10n.playbackGroupStartup),
            SettingsGroupCard(children: [
              SettingsSwitchTile(
                title: l10n.autoResume,
                subtitle: l10n.autoResumeDesc,
                value: p.autoResume,
                onChanged: ctrl.setAutoResume,
                info: l10n.autoResumeInfo,
              ),
              SettingsSwitchTile(
                title: l10n.defaultShuffle,
                subtitle: l10n.defaultShuffleDesc,
                value: p.defaultShuffle,
                onChanged: ctrl.setDefaultShuffle,
                info: l10n.defaultShuffleInfo,
              ),
              SettingsChoiceTile<int>(
                title: l10n.defaultRepeat,
                subtitle: l10n.defaultRepeatDesc,
                value: p.defaultRepeat,
                options: const [0, 1, 2],
                labelOf: (v) => switch (v) {
                  1 => l10n.repeatAll,
                  2 => l10n.repeatOne,
                  _ => l10n.repeatNone,
                },
                onChanged: ctrl.setDefaultRepeat,
                info: l10n.defaultRepeatInfo,
              ),
            ]),

            // --- Ses işleme: ses verisine uygulanan işlemler ---
            SettingsSectionHeader(title: l10n.playbackGroupAudioProcessing),
            SettingsGroupCard(children: [
              SettingsSwitchTile(
                title: l10n.skipSilence,
                subtitle: l10n.skipSilenceDesc,
                value: p.skipSilence,
                onChanged: ctrl.setSkipSilence,
                info: l10n.skipSilenceInfo,
              ),
              // Görev 2.3: ReplayGain anahtarı. just_audio setAudioSources ile
              // yüklenen kuyruklarda kesintisiz geçişi zaten varsayılan olarak
              // sağladığından, hiçbir şey yapmayan "Kesintisiz oynatma"
              // anahtarı (Görev 2.2) bu sayfadan kaldırıldı; modeldeki gapless
              // alanı eski JSON'ların uyumluluğu için korunuyor.
              SettingsSwitchTile(
                title: l10n.replayGain,
                subtitle: l10n.replayGainEnableDesc,
                value: p.replayGain,
                onChanged: ctrl.setReplayGain,
                info: l10n.replayGainInfo,
              ),
            ]),
          ],
        );
      }),
    );
  }
}
