import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

/// UI tasarım güncellemesi: hız ve perde sheet'i tasarım bileşenleriyle
/// yeniden düzenlendi — değer rozetli kaydırıcılar, hızlı hız çipleri
/// (0.8x / 1.0x / 1.25x / 1.5x) ve sıfırlama eylemi.
///
/// Tasarımdaki "yarımton" pitch sunumu EKLENMEDİ: model doğrusal oranı
/// (0.5x-2.0x) saklar; x biçimi gerçek değeri yansıtır. Controller
/// bağlantıları (PreferencesController + PlayerController) aynen korunur.
class SpeedPitchSheet extends StatelessWidget {
  const SpeedPitchSheet({super.key});

  static const List<double> _quickSpeeds = <double>[0.8, 1.0, 1.25, 1.5];

  /// Çip etiketi: 1x, 0.8x, 1.5x, 1.25x (gereksiz sıfır yok).
  static String _speedLabel(double v) {
    if (v % 1 == 0) return '${v.toStringAsFixed(0)}x';
    if ((v * 10) % 1 == 0) return '${v.toStringAsFixed(1)}x';
    return '${v.toStringAsFixed(2)}x';
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SpeedPitchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = Get.find<PreferencesController>();
    final player = Get.find<PlayerController>();

    void setSpeed(double v) {
      ctrl.setSpeed(v);
      player.setSpeed(v);
    }

    void setPitch(double v) {
      ctrl.setPitch(v);
      player.setPitch(v);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.playbackSpeedPitch,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Obx(() {
              final speed = ctrl.playback.value.speed;
              final pitch = ctrl.playback.value.pitch;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Çalma hızı ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.playbackSpeed,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${speed.toStringAsFixed(2)}x',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: speed.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    label: '${speed.toStringAsFixed(2)}x',
                    onChanged: setSpeed,
                  ),
                  Row(
                    children: [
                      for (final q in _quickSpeeds) ...[
                        Expanded(
                          child: _QuickChip(
                            label: _speedLabel(q),
                            active: (speed - q).abs() < 0.001,
                            onTap: () => setSpeed(q),
                          ),
                        ),
                        if (q != _quickSpeeds.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- Perde ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.playbackPitch,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${pitch.toStringAsFixed(2)}x',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: pitch.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    label: '${pitch.toStringAsFixed(2)}x',
                    onChanged: setPitch,
                  ),
                ],
              );
            }),
            const SizedBox(height: 4),
            // Sıfırla: 1.0 hız + 1.0 perde (mevcut controller API'si).
            FilledButton.tonalIcon(
              onPressed: () {
                ctrl.setSpeed(1.0);
                ctrl.setPitch(1.0);
                player.setSpeed(1.0);
                player.setPitch(1.0);
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.playbackReset),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hızlı hız çipi: aktif değer secondary-container dolgulu.
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: active ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
