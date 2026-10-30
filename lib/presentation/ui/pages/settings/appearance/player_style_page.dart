import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';

class PlayerStylePage extends StatelessWidget {
  const PlayerStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themePlayerTitle)),
      body: Obx(() {
        final p = themeCtrl.settings.value.player;

        return ListView(
          children: <Widget>[
            // Gün 12: dekoratif '—' başlığı kaldırıldı (tek tasarım dili:
            // başlıklar gerçek ad taşır); sabit 'Background'/'Artwork shape'
            // /'Mini player' başlıkları ve 'Wide'/'Compact' etiketleri l10n.
            SettingsChoiceTile<String>(
              title: l10n.playerBackgroundTitle,
              subtitle: l10n.playerBackgroundDesc,
              value: p.backgroundStyle,
              options: const <String>['solid', 'gradient', 'blur'],
              labelOf: (v) => switch (v) {
                'gradient' => l10n.playerBackgroundGradient,
                'blur' => l10n.playerBackgroundBlur,
                _ => l10n.playerBackgroundSolid,
              },
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(backgroundStyle: v)),
            ),
            SettingsChoiceTile<String>(
              title: l10n.playerArtworkShapeTitle,
              subtitle: l10n.playerArtworkShapeDesc,
              value: p.artworkShape,
              options: const <String>['square', 'rounded', 'circle'],
              labelOf: (v) => switch (v) {
                'square' => l10n.playerArtworkSquare,
                'circle' => l10n.playerArtworkCircle,
                _ => l10n.playerArtworkRounded,
              },
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(artworkShape: v)),
            ),
            SettingsChoiceTile<String>(
              title: l10n.seekBarStyle,
              subtitle: l10n.seekBarStyleDesc,
              value: p.seekBarStyle == 'waveform' ? 'classic' : p.seekBarStyle,
              options: const <String>['classic', 'thin'],
              labelOf: (v) =>
                  v == 'thin' ? l10n.seekBarThin : l10n.seekBarClassic,
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(seekBarStyle: v)),
            ),
            SettingsChoiceTile<String>(
              title: l10n.miniPlayerStyleTitle,
              subtitle: l10n.miniPlayerStyleDesc,
              value: p.miniPlayerStyle,
              options: const <String>['compact', 'wide'],
              labelOf: (v) =>
                  v == 'wide' ? l10n.miniPlayerWide : l10n.miniPlayerCompact,
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(miniPlayerStyle: v)),
            ),
            // Görev 3.3: animasyon seviyesi. Alan modelde ve JSON dönüşümünde
            // zaten vardı; ne arayüz seçeneği ne de tüketicisi olduğu için ölü
            // duruyordu. "Kapalı" seviye dekoratif gölgeleri (kapak parıltısı,
            // mini player gölgesi) çizmez; düşük donanımda akıcılık kazandırır.
            SettingsChoiceTile<String>(
              title: l10n.themeAnimationLevel,
              subtitle: l10n.themeAnimationLevelDesc,
              value: p.animationLevel,
              options: const <String>['full', 'reduced', 'none'],
              labelOf: (v) => switch (v) {
                'reduced' => l10n.animReduced,
                'none' => l10n.animNone,
                _ => l10n.animFull,
              },
              onChanged: (v) =>
                  themeCtrl.setPlayer(p.copyWith(animationLevel: v)),
            ),
          ],
        );
      }),
    );
  }
}