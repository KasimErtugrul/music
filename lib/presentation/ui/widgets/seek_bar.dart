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
      
      // Eğer süre 0 ise (henüz yüklenmediyse) barı boş göster
      final max = totalMs > 0 ? totalMs.toDouble() : 1.0;
      final value = currentMs.clamp(0, max).toDouble();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: widget.compact ? 2.0 : 4.0,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: widget.compact ? 4.0 : 6.0,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: widget.compact ? 8.0 : 12.0,
              ),
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
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    Duration(milliseconds: totalMs).clock,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}