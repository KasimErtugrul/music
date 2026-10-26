import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              l10n.homeNowPlaying.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(() => Text(
              controller.currentSong?.album ?? l10n.unknownAlbum,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: l10n.sleepTimer,
            onPressed: () => SleepTimerSheet.show(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Arka Plan Katmanı (Solid, Gradient veya Blur)
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
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        color: theme.colorScheme.surface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // 2. İçerik
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    Responsive.fromWidth(constraints.maxWidth) != WindowSize.compact;
                if (isWide) return const PlayerExpandedView();

                return Column(
                  children: [
                    const Spacer(),
                    // Kapak Görseli ve Atmosferik Işık
                    Obx(() {
                      final song = controller.currentSong;
                      if (song == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow Efekti
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(borderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ArtworkImage(
                                songId: song.id,
                                borderRadius: BorderRadius.circular(borderRadius),
                                fallbackIcon: Icons.music_note,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Şarkı Bilgisi ve LRC/Favori Butonları
                    Obx(() {
                      final song = controller.currentSong;
                      if (song == null) return const SizedBox.shrink();
                      final favCtrl = Get.find<FavoriteController>();
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist ?? l10n.unknownArtist,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Favori Butonu
                            Obx(() {
                              final isFav = favCtrl.isFavorite(song.id);
                              return IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                                onPressed: () => favCtrl.toggle(song),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    
                    const Spacer(),
                    
                    // Seek Bar
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SeekBar(),
                    ),
                    
                    // Ana Kontroller
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: PlayerControls(),
                    ),

                    // İkincil Eylem Satırı (-10s, Hız, Sözler, +10s, Kuyruk)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // -10s
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            tooltip: l10n.rewind10,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () {
                              final newPos = controller.position.value - const Duration(seconds: 10);
                              controller.seek(newPos.isNegative ? Duration.zero : newPos);
                            },
                          ),
                          // Hız
                          ActionChip(
                            label: Text('1.0x', style: theme.textTheme.labelMedium),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            side: BorderSide.none,
                            onPressed: () => SpeedPitchSheet.show(context),
                          ),
                          // Sözler (Kapsam Dışı)
                          IconButton(
                            icon: const Icon(Icons.format_quote),
                            tooltip: l10n.lyrics,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () => Get.snackbar(l10n.lyrics, 'Kapsam dışı (Gün 25)'),
                          ),
                          // +10s
                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            tooltip: l10n.forward10,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () {
                              final newPos = controller.position.value + const Duration(seconds: 10);
                              controller.seek(newPos);
                            },
                          ),
                          // Kuyruk / Waveform
                          IconButton(
                            icon: const Icon(Icons.graphic_eq),
                            tooltip: l10n.waveformViewer,
                            iconSize: 28,
                            color: theme.colorScheme.primary,
                            onPressed: () => Get.to(() => const WaveformViewerPage()),
                          ),
                        ],
                      ),
                    ),
                    
                    // Alt Sürükleme Tutamacı (Görsel)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kuyruğu görmek için yukarı kaydır',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
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