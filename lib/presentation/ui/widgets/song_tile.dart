import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queueContext,
    this.onTap,
    this.trailing,
    this.height = 72,
    this.playlistId,
    this.showPlaylistBadge = false,
    this.detailed = false,
  });

  final SongModel song;
  final List<SongModel>? queueContext;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double height;

  /// Gün 19: satır bir playlist detayındaysa seçenekler sayfası
  /// «Bu listeden çıkar» eylemini de gösterir; null ise menü kümesine
  /// dokunulmaz (kütüphane, arama, kuyruk vb. davranış değişmez).
  final int? playlistId;

  /// Gün 21: true ise satır, şarkının içinde bulunduğu çalma
  /// listelerini küçük bir rozetle gösterir. Yalnızca kütüphane
  /// sekmesindeki «Şarkılar» görünümü açar; albüm/sanatçı/arama
  /// gibi sayfalar bugünkü görünümünü korur. PlaylistController
  /// kayıtlı değilse (binding'siz pompalanan testler) rozet sessizce
  /// atlanır — «not found» patlaması yok.
  final bool showPlaylistBadge;

  /// Zengin kart şablonu (V3 — kullanıcı şablonu, dört satırlık sütun):
  /// 1. Şarkı adı → 2. Albüm adı → 3. Varsa çalma listesi rozeti →
  /// 4. «MP3/128kbps» biçiminde format satırı.
  /// Kart 96dp yüksekliktedir (kapak 56dp); kütüphane «Şarkılar» ve
  /// kuyruk sayfası («Sıradakiler» + «Son çalınanlar») AYNI şablonu
  /// kullanır — tek şablon ilkesi, kart yapısı tek yerde tanımlı.
  /// Kompakt (72dp) mod: sanatçı • albüm alt başlığı + isteğe bağlı
  /// rozet; «ÇALIYOR» etiketi de yalnızca kompakt modda çizilir.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = Get.find<PlayerController>();
    final favCtrl = Get.find<FavoriteController>();
    final theme = Theme.of(context);
    final artSize = detailed ? 56.0 : 48.0;

    // Büyük sistem yazı tipi ölçeğinde kart taşmasını önler:
    // metinler en çok 1.3x ölçeklenir; satır yükseklikleri (height:
    // 1.2) sabit tutulduğu için 84/72dp kutulara daima sığar.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Obx(() {
        final isCurrent = player.currentItem.value?.id == song.uri;
        final isPlaying = player.isPlaying.value;
        final isFav = favCtrl.isFavorite(song.id);

        // Gün 21: üyelik rozeti yalnızca bayrak açıksa ve playlist
        // motoru kayıtlıysa okunur. Okuma Obx içinde olduğu için
        // listeler değişince satır kendiliğinden güncellenir.
        final listNames =
            showPlaylistBadge && Get.isRegistered<PlaylistController>()
            ? Get.find<PlaylistController>().listNamesOf(song.id)
            : const <String>[];

        // V3 şablonu: zengin kartın ikinci satırı ALBÜM adıdır;
        // «sanatçı • albüm» birleşimi yalnızca kompakt modda kalır.
        final subtitle = detailed
            ? (song.album ?? l10n.unknownAlbum)
            : <String>[
                song.artist ?? l10n.unknownArtist,
                song.album ?? l10n.unknownAlbum,
              ].join(' • ');

        // 4. satır: «MP3/128kbps» (kullanıcı şablonu). Uzantı yoksa
        // yalnız bit hızı, o da yoksa satır hiç çizilmez.
        final codec = _codecLabel(song.path);
        final kbps = _averageBitrateKbps(song);
        final String? formatLabel;
        if (codec != null && kbps != null) {
          formatLabel = '$codec/${kbps}kbps';
        } else if (codec != null) {
          formatLabel = codec;
        } else if (kbps != null) {
          formatLabel = '${kbps}kbps';
        } else {
          formatLabel = null;
        }
        final lossless =
            codec != null && _losslessExtensions.contains(codec.toLowerCase());

        return SizedBox(
          height: height,
          child: Material(
            color: isCurrent
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (onTap != null) {
                  onTap!();
                } else {
                  player.playSong(song, queue: queueContext);
                }
              },
              onLongPress: () =>
                  SongOptionsSheet.show(context, song, playlistId: playlistId),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Sol: Kapak ve Equalizer
                    SizedBox(
                      width: artSize,
                      height: artSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ArtworkImage(
                            songId: song.id,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          if (isCurrent)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _AnimatedEqualizer(isPlaying: isPlaying),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Orta: Başlık, Alt Başlık ve Liste Rozeti
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.2,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isCurrent && !detailed) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.nowPlayingBadge.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      height: 1.2,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                          if (detailed) ...[
                            // 3. satır: varsa çalma listeleri (rozet
                            // kendi satırında — kullanıcı şablonu).
                            if (listNames.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: PlaylistBadge(names: listNames),
                                    ),
                                  ],
                                ),
                              ),
                            // 4. satır: «MP3/128kbps»; kayıpsız codec'te
                            // vurgu rengi (kütüphane ipucunun kart
                            // karşılığı). Düz metin — çip kalabalığı yok.
                            if (formatLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  formatLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: lossless
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ] else if (listNames.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: PlaylistBadge(names: listNames),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Sağ: Favori, Süre, Seçenekler
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            size: 20,
                          ),
                          onPressed: () => favCtrl.toggle(song),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          song.duration.clock,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: () => SongOptionsSheet.show(
                            context,
                            song,
                            playlistId: playlistId,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Gün 21: şarkının üyesi olduğu çalma listelerini gösteren rozet.
/// Tek satıra sığar: ilk listenin adı, varsa kalan sayısı
/// («Spor +2» biçimi). Liste adı kullanıcı verisidir; çevrilmez.
///
/// Bulgu 2: artık yalnızca SongTile'ın değil, oynatıcı ekranının da
/// kullanımına açık — aynı görsel dil şarkı kartlarında ve player
/// sayfasında aynen korunur.
class PlaylistBadge extends StatelessWidget {
  const PlaylistBadge({super.key, required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = names.length == 1
        ? names.first
        : '${names.first} +${names.length - 1}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ZENGİN KART YARDIMCILARI ==========

/// Kayıpsız codec uzantıları: format satırı bu kümedeyken vurgu
/// rengiyle (tertiary) çizilir (kütüphane başlığındaki «kayıpsız»
/// ipucunun kart karşılığı).
const Set<String> _losslessExtensions = {
  'flac',
  'wav',
  'alac',
  'aiff',
  'aif',
  'ape',
  'wv',
  'dsf',
  'dsd',
};

/// Dosya uzantısından codec etiketi üretir («/music/a.flac» → «FLAC»).
/// Uzantı yoksa, 5 karakterden uzunsa (yol bozuk demektir) null döner.
String? _codecLabel(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return null;
  final ext = path.substring(dot + 1).toLowerCase();
  if (ext.isEmpty || ext.length > 5 || ext.contains('/')) return null;
  return ext.toUpperCase();
}

/// Dosya boyutu ve süreden ortalama bit hızı (kbps). Ortalama olduğu
/// için kayıplı codec'lerde etikete (örn. MP3 320) yaklaşır; kayıpsız
/// codec'lerde de güç players'ın gösterdiği anlamlı büyüklüğü verir.
int? _averageBitrateKbps(SongModel song) {
  if (song.durationMs <= 0 || song.sizeBytes <= 0) return null;
  final kbps = (song.sizeBytes * 8) / (song.durationMs / 1000.0) / 1000.0;
  return kbps > 0 ? kbps.round() : null;
}

class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer({required this.isPlaying});
  final bool isPlaying;

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(color, 0.2, 0.8),
            _bar(color, 0.8, 0.2),
            _bar(color, 0.4, 1.0),
          ],
        );
      },
    );
  }

  Widget _bar(Color color, double min, double max) {
    final height = 8 + (16 * (widget.isPlaying ? _controller.value : min));
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
