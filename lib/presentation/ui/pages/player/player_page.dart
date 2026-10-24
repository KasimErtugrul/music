import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/pages/player/player_expanded_view.dart';
import 'package:resonance/presentation/ui/pages/waveform_viewer_page.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';
import 'package:resonance/presentation/ui/widgets/sleep_timer_sheet.dart';
import 'package:resonance/presentation/ui/widgets/speed_pitch_sheet.dart';
 
class PlayerPage extends GetView<PlayerController> {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final playerSettings = Theme.of(context).extension<PlayerThemeExtension>() ??
        PlayerThemeExtension.defaults;
    final bgStyle = playerSettings.backgroundStyle;
    final artworkShape = playerSettings.artworkShape;

    final borderRadius = switch (artworkShape) {
      'circle' => 200.0,
      'square' => 0.0,
      _ => 24.0,
    };

    return Scaffold(
      extendBodyBehindAppBar: bgStyle != 'solid',
      appBar: AppBar(
        title: Text(l10n.playerTitle),
        backgroundColor: bgStyle == 'solid' ? null : Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          if (bgStyle == 'gradient')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          if (bgStyle == 'blur')
            Obx(() {
              final songId = controller.currentSong?.id;
              if (songId == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ArtworkImage(songId: songId, fit: BoxFit.cover),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    Responsive.fromWidth(constraints.maxWidth) != WindowSize.compact;
                if (isWide) return const PlayerExpandedView();

                return Column(
                  children: [
                    const Spacer(),
                    Obx(() {
                      final song = controller.currentSong;
                      if (song == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ArtworkImage(
                            songId: song.id,
                            borderRadius: BorderRadius.circular(borderRadius),
                            fallbackIcon: Icons.music_note,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    Obx(() {
                      final song = controller.currentSong;
                      if (song == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              song.title,
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.artist ?? l10n.unknownArtist,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SeekBar(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: PlayerControls(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.graphic_eq),
                          tooltip: l10n.waveformViewer,
                          onPressed: () =>
                              Get.to(() => const WaveformViewerPage()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.speed),
                          tooltip: l10n.playbackSpeedPitch,
                          onPressed: () => SpeedPitchSheet.show(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer_outlined),
                          tooltip: l10n.sleepTimer,
                          onPressed: () => SleepTimerSheet.show(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}