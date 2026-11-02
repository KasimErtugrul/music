import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/pages/player/player_expanded_view.dart';
import 'package:resonance/presentation/ui/pages/waveform_viewer_page.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';
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

    // Bulgu 5: AppBar kaldırıldı. Eski AppBar'da «ŞİMDİ ÇALIYOR + albüm»
    // başlığı ve kuyruk ikonu vardı; başlık bilgisi ekranın gövdesinde
    // zaten var, kuyruğa ise alttaki tutamakla (dokunma/yukarı kaydırma)
    // erişiliyor. Şimdi yalnızca kapatma ve uyku zamanlayıcı için ince,
    // arka planın ÜZERİNE çizilen bir üst satır var.
    return Scaffold(
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

          // 2. İçerik — üst satır (kapat + uyku zamanlayıcı) ve gövde
          SafeArea(
            child: Column(
              children: [
                _PlayerTopBar(l10n: l10n),
                Expanded(
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
                      // Aşama 2: format rozeti (codec · kHz · bit/kbps).
                      // Aynı Obx formatInfo'yı da izler; bilgi yoksa gizlenir.
                      final fmtLabel = controller.formatInfo.value?.label;

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
                                  if (fmtLabel != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        left: 2,
                                      ),
                                      child: Text(
                                        fmtLabel,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.8),
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  // Bulgu 2: şarkının üyesi olduğu çalma
                                  // listeleri oynatıcı ekranında da görünür.
                                  _SongPlaylistChips(songId: song.id),
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
            ),
          ],
      ),
    );
  }
}

/// Bulgu 2: çalan şarkının üyesi olduğu çalma listelerini gösteren çip
/// satırı. SongTile'daki rozetle aynı görsel dili kullanır (PlaylistBadge).
/// PlaylistController kayıtlı değilse (binding'siz testler) sessizce
/// yok olur; şarkı hiçbir listede değilse satır hiç çizilmez.
class _SongPlaylistChips extends StatelessWidget {
  const _SongPlaylistChips({required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PlaylistController>()) {
      return const SizedBox.shrink();
    }
    final playlistCtrl = Get.find<PlaylistController>();
    return Obx(() {
      final names = playlistCtrl.listNamesOf(songId);
      if (names.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [for (final n in names) PlaylistBadge(names: [n])],
        ),
      );
    });
  }
}

/// Bulgu 5: AppBar'ın yerini alan ince üst satır. Sol: oynatıcıyı kapat
/// (aşağı ok). Sağ: uyku zamanlayıcı. Kuyruk ikonu bilinçli olarak
/// YOKTUR — alttaki sürükleme tutamağı (dokunma / yukarı kaydırma) aynı
/// işi yapar ve kullanıcının talebi üzerine ikon kaldırıldı.
class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            tooltip: l10n.backToParent,
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: l10n.sleepTimer,
            onPressed: () => SleepTimerSheet.show(context),
          ),
        ],
      ),
    );
  }
}
