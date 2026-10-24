import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/waveform_controller.dart';

class WaveformViewerPage extends StatefulWidget {
  const WaveformViewerPage({super.key});

  @override
  State<WaveformViewerPage> createState() => _WaveformViewerPageState();
}

class _WaveformViewerPageState extends State<WaveformViewerPage> {
  double? _dragProgress;
  Worker? _songWorker;

  @override
  void initState() {
    super.initState();
    final player = Get.find<PlayerController>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrent());

    _songWorker = ever<MediaItem?>(player.currentItem, (_) {
      if (mounted) setState(() => _dragProgress = null);
      _loadCurrent();
    });
  }

  void _loadCurrent() {
    final player = Get.find<PlayerController>();
    final waveCtrl = Get.find<WaveformController>();
    final song = player.currentSong;
    if (song != null && song.path.isNotEmpty) {
      waveCtrl.load(song.path);
    } else {
      waveCtrl.clear();
    }
  }

  @override
  void dispose() {
    _songWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final player = Get.find<PlayerController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.waveformViewer)),
      body: SafeArea(
        child: Obx(() {
          final song = player.currentSong;
          if (song == null) {
            return Center(child: Text(l10n.playerNoSong));
          }
          if (song.path.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.waveformNoFilePath,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? l10n.unknownArtist,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(child: _buildBody(context, l10n, theme, player)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text(player.position.value.clock,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player.duration.value.clock,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    PlayerController player,
  ) {
    final waveCtrl = Get.find<WaveformController>();

    return Obx(() {
      // ---- Yükleniyor ----
      if (waveCtrl.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(minHeight: 6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.waveformPreparing,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n.waveformFirstTimeNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // ---- Sonuç yok / desteklenmiyor ----
      final wave = waveCtrl.waveform.value;
      if (wave == null || wave.waveformData.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.waveformUnavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }

      // ---- Dalga formu ----
      return LayoutBuilder(
        builder: (context, constraints) {
          final totalMs = player.duration.value.inMilliseconds;
          final currentMs = _dragProgress != null
              ? (_dragProgress! * totalMs).toInt()
              : player.position.value.inMilliseconds;
          final progress = totalMs > 0 ? currentMs / totalMs : 0.0;

          return GestureDetector(
            onHorizontalDragStart: (d) {
              if (constraints.maxWidth <= 0) return;
              setState(() => _dragProgress =
                  (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0));
            },
            onHorizontalDragUpdate: (d) {
              if (constraints.maxWidth <= 0) return;
              setState(() => _dragProgress =
                  (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0));
            },
            onHorizontalDragEnd: (_) {
              if (_dragProgress != null && totalMs > 0) {
                player.seek(
                  Duration(milliseconds: (_dragProgress! * totalMs).toInt()),
                );
              }
              setState(() => _dragProgress = null);
            },
            onTapDown: (d) {
              if (constraints.maxWidth <= 0 || totalMs <= 0) return;
              final p =
                  (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              player.seek(Duration(milliseconds: (p * totalMs).toInt()));
            },
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomPaint(
                  painter: _WaveformPainter(
                    data: wave.waveformData,
                    progress: progress,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.data,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth = size.width / data.length;
    final centerY = size.height / 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth;
      final rawHeight = data[i].abs() * (size.height / 2);
      final barHeight = rawHeight.clamp(1.0, size.height / 2);
      final isPlayed = (i / data.length) <= progress;
      paint.color = isPlayed ? activeColor : inactiveColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            centerY - barHeight,
            (barWidth * 0.8).clamp(1.0, barWidth),
            barHeight * 2,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.data != data ||
        oldDelegate.activeColor != activeColor;
  }
}