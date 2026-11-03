import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/player_controls.dart';
import 'package:resonance/presentation/ui/widgets/seek_bar.dart';
import 'package:resonance/presentation/ui/widgets/song_playlist_chips.dart';

/// Geniş ekran (tablet / yatay) oynatıcı düzeni.
///
/// Bulgu 7: bu düzen daha önce «Oynatıcı görünümü» ayarlarının çoğunu
/// yok sayıyordu — kapak köşesi 32'ye sabitti (artworkShape okunmuyor),
/// animasyon seviyesi 'none' olsa bile parıltı yoktu/çizim mantığı
/// ayara bağlı değildi. Artık kompakt düzendeyle AYNI PlayerThemeExtension
/// değerlerini kullanır: backgroundStyle sayfanın kendisinde zaten
/// uygulanır; burada artworkShape ve animationLevel uygulanır.
class PlayerExpandedView extends GetView<PlayerController> {
  const PlayerExpandedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final playerSettings = theme.extension<PlayerThemeExtension>() ??
        PlayerThemeExtension.defaults;
    final artworkShape = playerSettings.artworkShape;
    final anim = playerSettings.animationLevel;

    // Kompakt düzenle aynı eşleme: circle → tam yuvarlak, square → keskin.
    final borderRadius = switch (artworkShape) {
      'circle' => 400.0,
      'square' => 0.0,
      _ => 32.0,
    };

    return Row(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              // Parıltı katmanı kare kapakla aynı sınırlar içinde çizilir
              // (StackFit.expand): aksi hâlde dekorasyonsuz Container satırın
              // tüm genişliğine yayılır ve parıltı «dikdörtgen» görünürdü.
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    // Bulgu 7: kapak parıltısı artık animasyon seviyesine
                    // duyarlı ('none' iken hiç çizilmez; 'reduced' yumuşak).
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
                    ArtworkImage(
                      songId: controller.currentSong?.id,
                      borderRadius: BorderRadius.circular(borderRadius),
                      fallbackIcon: Icons.music_note,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentSong?.title ?? '',
                  style: theme.textTheme.displaySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Sanatçı adına dokununca sanatçının tüm şarkılarını
                // gösteren detay sayfası açılır.
                InkWell(
                  onTap: controller.openArtistDetail,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                    child: Text(
                      controller.currentSong?.artist ?? l10n.unknownArtist,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                // Aşama 2: format rozeti (codec · kHz · bit/kbps).
                Obx(() {
                  final label = controller.formatInfo.value?.label;
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                // Bulgu 2/3: üye olunan çalma listeleri geniş düzende de
                // görünür; tüm yüzeyler aynı paylaşılan çip bileşenini
                // kullanır (SongPlaylistChips).
                Obx(() {
                  final song = controller.currentSong;
                  if (song == null) return const SizedBox.shrink();
                  return SongPlaylistChips(songId: song.id);
                }),
                const SizedBox(height: 64),
                const SeekBar(),
                const SizedBox(height: 32),
                const PlayerControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
