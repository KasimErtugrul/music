import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

/// Harici dosya oynatıcı — sistem dosya yöneticisinden "Resonance ile aç"
/// ile gelen dosyanın özel oynatma ekranı (M3 tasarım güncellemesi).
///
/// - Turntable görseli: dosya kütüphanede olmadığı için kapak verisi yoktur;
///   dönen plak + gerçek biçim rozeti (uzantıdan) gösterilir, dönme animasyonu
///   gerçek çalma durumuyla senkrondur
/// - Teknik ızgara: yalnızca gerçek veriler (biçim, canlı süre, hız, tekrar
///   modu). Örnekleme hızı/bit derinliği verisi MediaStore'dan gelmediği için
///   eklenmedi
/// - Kaydırıcı + zaman etiketleri canlı position/duration akışından beslenir
/// - Eylemler: ±geri/ileri (tercih aralığı), oynat/duraklat, hız döngüsü,
///   tekrar modu döngüsü, kuyruğa ekle, kütüphaneyi yeniden tara
///
/// Tasarımdaki "Etiketleri Düzenle", "Ekolayzır Profiline Uygula" ve
/// favori düğmesi EKLENMEDİ: harici dosyanın dosya yolu boştur (content://)
/// ve favoriler kütüphane kimliğine bağlıdır (README).
class ExternalPlayerPage extends StatefulWidget {
  const ExternalPlayerPage({super.key});

  @override
  State<ExternalPlayerPage> createState() => _ExternalPlayerPageState();
}

class _ExternalPlayerPageState extends State<ExternalPlayerPage>
    with SingleTickerProviderStateMixin {
  SongModel? _song;
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _song = Get.arguments as SongModel?;
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  String? get _formatLabel {
    final song = _song;
    if (song == null) return null;
    final source = song.path.isNotEmpty ? song.path : song.uri;
    final dot = source.lastIndexOf('.');
    if (dot < 0 || dot == source.length - 1) return null;
    return source.substring(dot + 1).toUpperCase();
  }

  String get _path {
    final song = _song;
    if (song == null) return '';
    return song.path.isNotEmpty ? song.path : song.uri;
  }

  static const List<double> _speeds = <double>[0.8, 1.0, 1.25, 1.5];

  void _cycleSpeed(PlayerController player, double current) {
    var idx = _speeds.indexWhere((s) => (s - current).abs() < 0.001);
    idx = (idx + 1) % _speeds.length;
    player.setSpeed(_speeds[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    if (_song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.externalOpenError)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.externalTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // --- Üst biçim şeridi ---
            Builder(builder: (_) {
              final ext = _formatLabel ?? 'AUDIO';
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          ext,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '•',
                          style:
                              TextStyle(color: cs.outlineVariant, fontSize: 11),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          l10n.externalTempNote,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _RoundAction(
                    icon: Icons.copy,
                    tooltip: l10n.commonCopy,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: _path));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.optionsPathCopied)),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              );
            }),

            // --- Turntable ---
            const SizedBox(height: 18),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 268,
                    height: 268,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          cs.primaryContainer.withValues(alpha: 0.28),
                          cs.tertiaryContainer.withValues(alpha: 0.10),
                          cs.primaryContainer.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 252,
                    height: 252,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Plak olukları
                          CustomPaint(
                            size: const Size(228, 228),
                            painter: _GroovesPainter(
                              color: cs.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          // Dönen plak göbeği
                          Obx(() {
                            final playing = player.isPlaying.value;
                            if (playing && !_spin.isAnimating) {
                              _spin.repeat();
                            } else if (!playing && _spin.isAnimating) {
                              _spin.stop();
                            }
                            return RotationTransition(
                              turns: _spin,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.graphic_eq,
                                      size: 34,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatLabel ?? 'AUDIO',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // İğne merkez pimi
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          // Rozetler
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: _MiniBadge(
                              icon: Icons.sd_card,
                              label: l10n.externalSourceBadge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Başlık + yol kartı ---
            const SizedBox(height: 16),
            Text(
              _song!.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              l10n.unknownArtist,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _path));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.optionsPathCopied)),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open,
                        size: 17, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy, size: 15, color: cs.outline),
                  ],
                ),
              ),
            ),

            // --- Teknik ızgara ---
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Obx(() {
                final speed = player.speed.value;
                final repeat = player.repeatMode.value;
                final repeatLabel = switch (repeat) {
                  AudioServiceRepeatMode.all => l10n.repeatAll,
                  AudioServiceRepeatMode.one => l10n.repeatOne,
                  _ => l10n.repeatNone,
                };
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, size: 17, color: cs.primary),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            l10n.externalSpecsTitle,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SpecCell(
                            icon: Icons.audio_file,
                            label: l10n.optionsMetaFormat,
                            value: _formatLabel ?? 'AUDIO',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SpecCell(
                            icon: Icons.schedule,
                            label: l10n.infoDuration,
                            value: player.duration.value.clock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SpecCell(
                            icon: Icons.speed,
                            label: l10n.playbackSpeed,
                            value: '${speed.toStringAsFixed(2)}x',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SpecCell(
                            icon: Icons.repeat,
                            label: l10n.queueTitle,
                            value: repeatLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),

            // --- Kaydırıcı ---
            const SizedBox(height: 16),
            Obx(() {
              final pos = player.position.value;
              final dur = player.duration.value;
              final maxMs = dur.inMilliseconds.toDouble();
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: maxMs > 0
                          ? pos.inMilliseconds.clamp(0, maxMs).toDouble()
                          : 0,
                      max: maxMs > 0 ? maxMs : 1,
                      onChanged: maxMs > 0
                          ? (v) => player.seek(
                              Duration(milliseconds: v.round()))
                          : null,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        pos.clock,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dur.clock,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),

            // --- Oynatma kontrolleri ---
            const SizedBox(height: 8),
            Obx(() {
              final repeat = player.repeatMode.value;
              final repeatActive = repeat !=
                  AudioServiceRepeatMode.none;
              final speed = player.speed.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: l10n.repeatNone,
                    onPressed: player.cycleRepeatMode,
                    icon: Icon(
                      repeat == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      size: 24,
                      color: repeatActive ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.rewind10,
                    onPressed: player.rewind,
                    icon: Icon(Icons.replay_10,
                        size: 28, color: cs.onSurface),
                  ),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: FilledButton(
                      onPressed: player.togglePlayPause,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: Obx(
                        () => Icon(
                          player.isPlaying.value
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.forward10,
                    onPressed: player.fastForward,
                    icon: Icon(Icons.forward_10,
                        size: 28, color: cs.onSurface),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _cycleSpeed(player, speed),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          '${speed.toStringAsFixed(1)}x',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // --- Eylemler ---
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                final lib = Get.find<LibraryController>();
                await lib.rescan();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.externalScanDone)),
                  );
                }
              },
              icon: const Icon(Icons.library_add, size: 21),
              label: Text(l10n.externalAddLibrary),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () {
                final song = _song!;
                Get.find<PlayerController>().addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.optionsAddedToQueue)),
                );
              },
              icon: const Icon(Icons.queue_music, size: 20),
              label: Text(l10n.addToQueue),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== PLAK OLUKLARI ==========

class _GroovesPainter extends CustomPainter {
  const _GroovesPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final r in const [58.0, 76.0, 94.0, 112.0]) {
      if (r < maxR) canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroovesPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ========== YARDIMCILAR ==========

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerHigh,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child:
                Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
