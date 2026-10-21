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
    final iconSize = compact ? 24.0 : 32.0;
    final playIconSize = compact ? 32.0 : 64.0;

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
          ? Theme.of(context).colorScheme.primary 
          : null;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!compact)
            IconButton(
              icon: Icon(Icons.shuffle, color: shuffle ? Theme.of(context).colorScheme.primary : null),
              iconSize: iconSize,
              onPressed: controller.toggleShuffle,
            ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: iconSize,
            onPressed: controller.previous,
          ),
          IconButton(
            icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
            iconSize: playIconSize,
            color: Theme.of(context).colorScheme.primary,
            onPressed: controller.togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: iconSize,
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