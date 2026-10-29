import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
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
import 'package:resonance/presentation/ui/widgets/state_views.dart';
import 'package:resonance/presentation/ui/widgets/sleep_timer_sheet.dart';
import 'package:resonance/presentation/ui/widgets/speed_pitch_sheet.dart';

/// Ek-B: Hız çipi etiketi. 1.0 → "1.0x", 1.5 → "1.5x", 1.25 → "1.25x".
String _speedLabel(double v) =>
    v == v.roundToDouble() ? '${v.toStringAsFixed(1)}x' : '${v.toStringAsFixed(2)}x';

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
    // Görev 3.3: animasyon seviyesi. 'none' dekoratif parıltıyı hiç üretmez;
    // 'reduced' daha yumuşak (düşük alfa + küçük blur) bir parıltı çizer.
    final anim = playerSettings.animationLevel;

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
            // Albüm adına dokununca albüm detay sayfası açılır
            // (sanatçı adındaki davranışın albüm kardeşi).
            Obx(() => InkWell(
              onTap: controller.openAlbumDetail,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                child: Text(
                  controller.currentSong?.album ?? l10n.unknownAlbum,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
          ],
        ),
        centerTitle: true,
        actions: [
          // Kuyruk: kullanıcı şarkıları kuyruğa ekleyebiliyor ama kuyruk
          // sayfasına hiçbir giriş noktası yoktu; AppBar'dan erişim eklendi.
          IconButton(
            icon: const Icon(Icons.queue_music_outlined),
            tooltip: l10n.queue,
            onPressed: () => Get.toNamed(AppRoutes.queue),
          ),
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
                            // Glow Efekti — Görev 3.3: animasyon seviyesine
                            // duyarlı. 'none' iken katman hiç üretilmez
                            // (düşük donanımda blend maliyeti ortadan kalkar).
                            if (anim != 'none')
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(borderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withValues(
                                        alpha: anim == 'reduced' ? 0.12 : 0.25,
                                      ),
                                      blurRadius: anim == 'reduced' ? 30 : 60,
                                      spreadRadius: anim == 'reduced' ? 5 : 10,
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
                                  // Sanatçı adına dokununca sanatçının tüm
                                  // şarkılarını gösteren detay sayfası açılır.
                                  InkWell(
                                    onTap: controller.openArtistDetail,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        song.artist ?? l10n.unknownArtist,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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

                    // İkincil Eylem Satırı (-Xs, Hız, Sözler, +Xs, Kuyruk)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Geri sarma — Görev 1.1: sabit 10 sn yerine
                          // controller.rewind() kullanılır; süre
                          // seekIntervalSeconds tercihi okunur (5/10/15/30 sn).
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            tooltip: l10n.rewind10,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: controller.rewind,
                          ),
                          // Hız — Ek-B: sabit '1.0x' yerine playbackState'ten
                          // beslenen canlı hız; ayar değişince etiket güncellenir.
                          Obx(() {
                            final spd = controller.speed.value;
                            return ActionChip(
                              label: Text(_speedLabel(spd),
                                  style: theme.textTheme.labelMedium),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              side: BorderSide.none,
                              onPressed: () => SpeedPitchSheet.show(context),
                            );
                          }),
                          // Sözler: şartname 6.15 durum görünümü
                          // (söz gösterimi bu sürümde kapsam dışıdır;
                          // düğme tasarlanmış bilgilendirme sheet'ini açar).
                          IconButton(
                            icon: const Icon(Icons.format_quote),
                            tooltip: l10n.lyrics,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () {
                              final song = controller.currentSong;
                              if (song != null) {
                                NoLyricsView.show(context, song);
                              }
                            },
                          ),
                          // İleri sarma — Görev 1.1: sabit 10 sn yerine
                          // controller.fastForward() kullanılır.
                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            tooltip: l10n.forward10,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: controller.fastForward,
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

                    // Alt Sürükleme Tutamacı — artık sadece görsel değil:
                    // dokunma ve yukarı kaydırma hareketi kuyruk sayfasını
                    // açar (yazıdaki vaat gerçek davranışa bağlandı).
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Get.toNamed(AppRoutes.queue),
                      onVerticalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        // Yukarı doğru hızlı kaydırma → kuyruk.
                        if (velocity < -120) {
                          Get.toNamed(AppRoutes.queue);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.swipeUpToSeeQueue,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
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
