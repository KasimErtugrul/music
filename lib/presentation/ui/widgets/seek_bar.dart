import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({super.key, this.compact = false});
  final bool compact;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = Theme.of(context);

    return Obx(() {
      final totalMs = controller.duration.value.inMilliseconds;
      final currentMs = _dragValue?.toInt() ?? controller.position.value.inMilliseconds;
      
      final max = totalMs > 0 ? totalMs.toDouble() : 1.0;
      final value = currentMs.clamp(0, max).toDouble();
      
      // Kalan süre hesabı
      final remainingMs = totalMs > 0 ? (totalMs - currentMs).clamp(0, totalMs) : 0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: widget.compact ? 2.0 : 3.0,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: widget.compact ? 4.0 : 5.0,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: widget.compact ? 8.0 : 12.0,
              ),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: (v) => setState(() => _dragValue = v),
              onChangeEnd: (v) {
                setState(() => _dragValue = null);
                controller.seek(Duration(milliseconds: v.round()));
              },
            ),
          ),
          if (!widget.compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Duration(milliseconds: currentMs).clock,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '-${Duration(milliseconds: remainingMs).clock}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}