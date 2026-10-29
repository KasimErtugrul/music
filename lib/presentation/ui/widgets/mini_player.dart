import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';

/// UI tasarım güncellemesi: mini oynatıcı artık alt gezinme çubuğunun
/// üzerinde yüzen YUVARLAK KÖŞELİ bir kart olarak çizilir (tasarımdaki
/// floating mini player). Kenar boşluğu kartın içinde verilir; hem compact
/// hem expanded yerleşimlerinde aynı görünümü alır.
///
/// Görev 3.3 (Aşama 3) aynen korunur: animasyon seviyesi gölgeyi ve kart ↔
/// tutamak boyut geçişini ölçekler — 'none' → animasyonsuz/düz çizim,
/// 'reduced' → yumuşak gölge ve kısa geçiş, aksi hâlde tam elevasyon.
///
/// Aşama 4: kaydırma hareketleri —
///  • aşağı kaydırma → kart ince bir tutamağa küçülür; tutamağa dokunmak
///    veya yukarı kaydırmak kartı geri açar (kalıcı gizleme yoktur,
///    kullanıcı her zaman tek dokunuşla geri döner)
///  • yukarı kaydırma → tam oynatıcıyı açar (dokunmayla aynı davranış)
///  • sola hızlı kaydırma (fling) → sonraki parça; sağa → önceki parça.
///    Kart içi SeekBar'ın yatay sürüklemesi kendi tanıyıcısıyla jest
///    yarışını kazanır (daha derin tanıyıcı önceliklidir); parça atlama
///    yalnızca kartın diğer yüzeylerinde fling ile tetiklenir.
class MiniPlayer extends GetView<PlayerController> {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerSettings = Theme.of(context).extension<PlayerThemeExtension>() ?? PlayerThemeExtension.defaults;
    final isWide = playerSettings.miniPlayerStyle == 'wide';

    // Görev 3.3: animasyon seviyesi mini player gölgesini de ölçekler.
    final elevation = switch (playerSettings.animationLevel) {
      'none' => 0.0,
      'reduced' => 4.0,
      _ => 8.0,
    };

    // Aşama 4: kart ↔ tutamak ↔ boş geçişleri yumuşak boyut geçişine
    // çeviren sarmalayıcı. Obx yalnızca hangi çocuğun çizileceğine karar
    // verir; boyut değişikliğini AnimatedSize animasyonla izler.
    final sizeAnimDuration = switch (playerSettings.animationLevel) {
      'none' => Duration.zero,
      'reduced' => const Duration(milliseconds: 150),
      _ => const Duration(milliseconds: 250),
    };

    return AnimatedSize(
      duration: sizeAnimDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Obx(() {
        if (controller.currentSong == null) {
          // Yalnızca yükseklik sıfıra insin; genişlik sabit kalsın ki
          // kapanışta yatay sıkışma görünümü oluşmasın.
          return const SizedBox(width: double.infinity);
        }
        if (controller.miniPlayerHidden.value) {
          return _MiniPlayerHandle(
            onRestore: controller.showMiniPlayer,
            tooltip: AppLocalizations.of(context).miniPlayerShow,
          );
        }
        return _MiniPlayerCard(isWide: isWide, elevation: elevation);
      }),
    );
  }
}

/// Aşama 4: kart gizlendiğinde onun yerini alan ince geri getirme tutamağı.
/// Ekran alanını fiilen boşaltır; kaybolan kartın yerine görünür ve
/// keşfedilebilir bir geri dönüş noktası sağlar (snackbar'a bağımlı değil).
class _MiniPlayerHandle extends StatelessWidget {
  const _MiniPlayerHandle({required this.onRestore, required this.tooltip});

  final VoidCallback onRestore;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRestore,
        onVerticalDragEnd: (details) {
          // Yukarı doğru kaydırma da geri açar (aşağı kaydırmanın tersi).
          if ((details.primaryVelocity ?? 0) < -120) onRestore();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
          child: Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yüzen mini player kartı. Aşama 4 hareket tanıyıcıları kartın en dış
/// katmanına alınır: içteki IconButton/Slider kendi tanıyıcıları jest
/// yarışını kazanmaya devam eder (derinlik önceliği), kart hareketleri
/// yalnızca iç denetimlerin iddia etmediği sürüklemelerde tetiklenir.
class _MiniPlayerCard extends GetView<PlayerController> {
  const _MiniPlayerCard({required this.isWide, required this.elevation});

  final bool isWide;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Tasarım: yüzen kart — yatayda kenar boşluğu, gezinme çubuğundan
      // önce hafif boşluk.
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Material(
        elevation: elevation,
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 120) {
              // Aşağı kaydırma → ince tutamağa küçül.
              controller.hideMiniPlayer();
            } else if (velocity < -120) {
              // Yukarı kaydırma → tam oynatıcı (dokunmayla aynı).
              Get.toNamed(AppRoutes.player);
            }
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            // Parça atlama kasıtlı bir fling ister; tesadüfi sürüklemeler
            // eşiği geçmesin. Sola → sonraki, sağa → önceki.
            if (velocity < -350) {
              controller.next();
            } else if (velocity > 350) {
              controller.previous();
            }
          },
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.player),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    ArtworkImage(
                      songId: controller.currentSong?.id,
                      size: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.currentSong!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            controller.currentSong!.artist ??
                                AppLocalizations.of(context).unknownArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: controller.previous,
                      ),
                      const PlayerControls(compact: true),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: controller.next,
                      ),
                    ] else ...[
                      const PlayerControls(compact: true),
                    ],
                    // Kuyruk: mini player'dan da sıradakilere tek dokunuşla
                    // erişim (kuyruk sayfasına ek giriş noktası).
                    IconButton(
                      icon: const Icon(Icons.queue_music_outlined),
                      tooltip: AppLocalizations.of(context).queue,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Get.toNamed(AppRoutes.queue),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                // İnce ilerleme çubuğu (alt kenara yapışık, kart köşeleri
                // clip'lenir)
                const SeekBar(compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
