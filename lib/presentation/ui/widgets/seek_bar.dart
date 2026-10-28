import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/extensions/player_theme_extension.dart';
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

      // Görev 3.2: sarma çubuğu stili artık PlayerThemeExtension.seekBarStyle
      // tarafından yönetilir. Eski sürüm eklentiyi hiç okumadığı için "Klasik"
      // ve "İnce" seçenekleri aynı görünümü veriyordu. İnce stil: daha ince
      // iz, küçük başparmak, dar vuruş alanı ve sadeleştirilmiş süre etiketi.
      final playerStyle =
          theme.extension<PlayerThemeExtension>() ?? PlayerThemeExtension.defaults;
      final thin = playerStyle.seekBarStyle == 'thin';

      final trackHeight = widget.compact ? 2.0 : (thin ? 1.4 : 3.0);
      final thumbRadius = widget.compact ? 4.0 : (thin ? 3.0 : 5.0);
      final overlayRadius = widget.compact ? 8.0 : (thin ? 9.0 : 12.0);

      final timeStyle = theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: thin ? null : FontWeight.w500,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: trackHeight,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: thumbRadius,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: overlayRadius,
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
                    style: timeStyle,
                  ),
                  Text(
                    '-${Duration(milliseconds: remainingMs).clock}',
                    style: timeStyle,
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
