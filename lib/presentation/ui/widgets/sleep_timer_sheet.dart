import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<SleepTimerController>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.sleepTimer, style: Theme.of(context).textTheme.titleLarge),
          ),
          Obx(() {
            if (ctrl.isActive.value) {
              final min = (ctrl.remainingSeconds.value / 60).ceil();
              final text = ctrl.isEndOfTrackMode.value 
                  ? l10n.sleepTimerEndOfTrackSet 
                  : l10n.sleepTimerSetFor(min);
              return Column(
                children: [
                  Text(text, style: Theme.of(context).textTheme.bodyLarge),
                  TextButton(
                    onPressed: ctrl.cancelTimer,
                    child: Text(l10n.commonCancel),
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in [15, 30, 45, 60])
                  ActionChip(
                    label: Text(l10n.minutesShort(m)),
                    onPressed: () => ctrl.startTimer(m),
                  ),
                ActionChip(
                  label: Text(l10n.sleepTimerEndOfTrack),
                  onPressed: () => ctrl.startEndOfTrack(),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}