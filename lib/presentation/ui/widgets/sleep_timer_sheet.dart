import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';

/// UI tasarım güncellemesi: uyku zamanlayıcısı sheet'i tasarım
/// bileşenleriyle yeniden düzenlendi — aktifken geri sayım kartı
/// (dakika:saniye) + süre ekleme + durdurma; pasifken 2x2 süre ızgarası ve
/// tam genişlikte "parça sonunda durdur" düğmesi.
///
/// Tasarımdaki ayrı "fade penceresi" kaydırıcısı EKLENMEDİ:
/// SleepTimerController'ın sönümlemesi son 10 saniyede sabit ve hacim
/// rampalı çalışır; uyumsuz bir pencere ayarı uydurmak yerine gerçek
/// davranış korunmuştur. "+5 dk", controller'ın startTimer API'siyle
/// kalan süreye eklenerek yeniden başlatır (gerçek zamanlayıcı eylemi).
class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  static String _mmss(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = Get.find<SleepTimerController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sleepTimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (ctrl.isEndOfTrackMode.value) {
                // Parça sonu modu aktif.
                return _ActiveCard(
                  icon: Icons.music_off,
                  iconColor: cs.onPrimaryContainer,
                  iconBg: cs.primaryContainer,
                  title: l10n.sleepTimerEndOfTrackSet,
                  actions: [
                    TextButton(
                      onPressed: ctrl.cancelTimer,
                      child: Text(l10n.commonCancel),
                    ),
                  ],
                );
              }

              if (ctrl.isActive.value) {
                final remaining = ctrl.remainingSeconds.value;
                final minutes = (remaining / 60).ceil();
                return _ActiveCard(
                  icon: Icons.bedtime,
                  iconColor: cs.onPrimaryContainer,
                  iconBg: cs.primaryContainer,
                  title: _mmss(remaining),
                  subtitle: l10n.sleepTimerRemaining,
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          ctrl.startTimer(minutes + 5),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.sleepTimerAddFive),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: ctrl.cancelTimer,
                      icon: const Icon(Icons.stop_circle, size: 18),
                      label: Text(l10n.commonCancel),
                    ),
                  ],
                );
              }

              // Pasif: süre ızgarası + parça sonu.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (final m in [15, 30]) ...[
                        Expanded(
                          child: _DurationButton(
                            label: l10n.minutesShort(m),
                            onTap: () => ctrl.startTimer(m),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final m in [45, 60]) ...[
                        Expanded(
                          child: _DurationButton(
                            label: l10n.minutesShort(m),
                            onTap: () => ctrl.startTimer(m),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: ctrl.startEndOfTrack,
                    icon: const Icon(Icons.music_off, size: 18),
                    label: Text(l10n.sleepTimerEndOfTrack),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Aktif zamanlayıcı kartı: ikon rozeti + büyük değer + eylem satırı.
class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.actions,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final a in actions) ...[
                a,
                if (a != actions.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Süre düğmesi (tasarımdaki preset chip'lerinin ızgara hâli).
class _DurationButton extends StatelessWidget {
  const _DurationButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
