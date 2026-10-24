import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/waveform_controller.dart';

class WaveformSeekBar extends StatefulWidget {
  const WaveformSeekBar({super.key});

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    final waveCtrl = Get.find<WaveformController>();
    final theme = Theme.of(context);

    return Obx(() {
      final song = player.currentSong;
      if (song == null) return const SizedBox.shrink();

      // Dosya yolu üzerinden yükle
      waveCtrl.load(song.path);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            child: Obx(() {
              if (waveCtrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              
              final wave = waveCtrl.waveform.value;
              if (wave == null || wave.waveformData.isEmpty) {
                // Fallback: Normal slider
                return const SizedBox.shrink(); 
              }

              final totalMs = player.duration.value.inMilliseconds;
              final currentMs = _dragProgress != null 
                  ? (_dragProgress! * totalMs).toInt() 
                  : player.position.value.inMilliseconds;

              return GestureDetector(
                onHorizontalDragStart: (d) => setState(() => _dragProgress = d.localPosition.dx / context.size!.width),
                onHorizontalDragUpdate: (d) => setState(() => _dragProgress = d.localPosition.dx / context.size!.width),
                onHorizontalDragEnd: (d) {
                  if (_dragProgress != null) {
                    player.seek(Duration(milliseconds: (_dragProgress! * totalMs).toInt()));
                    setState(() => _dragProgress = null);
                  }
                },
                onTapDown: (d) {
                  final progress = d.localPosition.dx / context.size!.width;
                  player.seek(Duration(milliseconds: (progress * totalMs).toInt()));
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _WaveformPainter(
                    data: wave.waveformData,
                    progress: totalMs > 0 ? currentMs / totalMs : 0.0,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(player.position.value.clock, style: theme.textTheme.bodySmall),
                Text(player.duration.value.clock, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
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
    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth = size.width / data.length;
    final centerY = size.height / 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth;
      final barHeight = data[i].abs() * (size.height / 2);
      
      // Çubuğun çizilme oranı (progress)
      final isPlayed = (i / data.length) <= progress;
      paint.color = isPlayed ? activeColor : inactiveColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            centerY - barHeight,
            barWidth * 0.8, // Çubuklar arası boşluk
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
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}