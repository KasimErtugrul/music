import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = Theme.of(context);
    final iconSize = compact ? 24.0 : 32.0;
    final playIconSize = compact ? 32.0 : 40.0;

    return Obx(() {
      final playing = controller.isPlaying.value;
      final shuffle = controller.shuffleEnabled.value;
      final repeat = controller.repeatMode.value;

      final repeatIcon = switch (repeat) {
        AudioServiceRepeatMode.none => Icons.repeat,
        AudioServiceRepeatMode.all => Icons.repeat,
        AudioServiceRepeatMode.one => Icons.repeat_one,
        _ => Icons.repeat,
      };
      
      final repeatColor = repeat != AudioServiceRepeatMode.none 
          ? theme.colorScheme.primary 
          : theme.colorScheme.onSurfaceVariant;
      
      final shuffleColor = shuffle 
          ? theme.colorScheme.primary 
          : theme.colorScheme.onSurfaceVariant;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!compact)
            IconButton(
              icon: Icon(Icons.shuffle, color: shuffleColor),
              iconSize: iconSize,
              onPressed: controller.toggleShuffle,
            ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: iconSize + 4,
            color: theme.colorScheme.onSurface,
            onPressed: controller.previous,
          ),
          
          // Tasarımdaki dolgulu (Filled) Büyük Buton
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              iconSize: playIconSize,
              color: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.all(12),
              onPressed: controller.togglePlayPause,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: iconSize + 4,
            color: theme.colorScheme.onSurface,
            onPressed: controller.next,
          ),
          if (!compact)
            IconButton(
              icon: Icon(repeatIcon, color: repeatColor),
              iconSize: iconSize,
              onPressed: controller.cycleRepeatMode,
            ),
        ],
      );
    });
  }
}