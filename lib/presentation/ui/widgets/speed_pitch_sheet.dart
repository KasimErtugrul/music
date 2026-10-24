import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class SpeedPitchSheet extends StatelessWidget {
  const SpeedPitchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SpeedPitchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<PreferencesController>();
    final player = Get.find<PlayerController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.playbackSpeedPitch, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Obx(() {
              final speed = ctrl.playback.value.speed;
              final pitch = ctrl.playback.value.pitch;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.playbackSpeed),
                      Text('${speed.toStringAsFixed(2)}x'),
                    ],
                  ),
                  Slider(
                    value: speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    onChanged: (v) {
                      ctrl.setSpeed(v);
                      player.setSpeed(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.playbackPitch),
                      Text('${pitch.toStringAsFixed(2)}x'),
                    ],
                  ),
                  Slider(
                    value: pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    onChanged: (v) {
                      ctrl.setPitch(v);
                      player.setPitch(v);
                    },
                  ),
                ],
              );
            }),
            TextButton(
              onPressed: () {
                ctrl.setSpeed(1.0);
                ctrl.setPitch(1.0);
                player.setSpeed(1.0);
                player.setPitch(1.0);
              },
              child: Text(l10n.playbackReset),
            ),
          ],
        ),
      ),
    );
  }
}