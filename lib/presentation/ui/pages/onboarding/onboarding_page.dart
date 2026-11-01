import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/onboarding_controller.dart';
import 'package:resonance/presentation/ui/pages/onboarding/onboarding_steps.dart';

/// Gün 18: 5 sayfalık onboarding iskeleti.
///
/// Düzen: üstte [geri | Atla], ortada PageView (kaydırmaya izinli),
/// altta nokta göstergesi + tek ana eylem düğmesi.
///
/// Ana eylem sözleşmesi:
/// - Sayfa 1-2: «İleri».
/// - Sayfa 3 (medya izni): izin verilmemişse düğme «İzin ver» olur —
///   karta gömülü düğmeyle aynı denetleyici çağrısını yapar; verildiyse
///   «İleri»ye döner. Böylece izin adımı tek bakışta yönlendiricidir.
/// - Sayfa 4 (bildirim izni): yalnızca izin gerekliyse ve verilmemişse
///   «İzin ver»; Android < 13'te gereksinim yoktur, doğrudan «İleri».
/// - Sayfa 5: «Başlayalım» → complete().
///
/// Sistem geri tuşu: ilk sayfada çıkışa bırakılır (canPop: true); diğer
/// sayfalarda bir önceki adıma döner — akıştan atlamak yerine.
class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Obx(
      () => PopScope(
        canPop: controller.currentPage.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.previous();
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(controller: controller, l10n: l10n),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    children: [
                      const OnboardingWelcomeStep(),
                      const OnboardingFeaturesStep(),
                      OnboardingMediaStep(controller: controller),
                      OnboardingNotificationStep(controller: controller),
                      OnboardingSummaryStep(controller: controller),
                    ],
                  ),
                ),
                _BottomBar(controller: controller, l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== ÜST BAR ==========

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.l10n});

  final OnboardingController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final index = controller.currentPage.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
        child: Row(
          children: [
            // Yer tutucu: ilk sayfada geri yok; satır yüksekliği sabit kalır.
            SizedBox(
              width: 48,
              height: 48,
              child: index > 0
                  ? IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: const Icon(Icons.arrow_back),
                      onPressed: controller.previous,
                    )
                  : null,
            ),
            const Spacer(),
            if (index < OnboardingController.totalPages - 1)
              TextButton(
                onPressed: controller.skip,
                child: Text(
                  l10n.onboardingSkip,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ========== ALT BAR ==========

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.l10n});

  final OnboardingController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final index = controller.currentPage.value;
      final isLast = controller.isLast;
      final busy = controller.permission.busy.value;

      // Ana eylem: izin adımlarında rehber «İzin ver», aksi hâlde gezinme.
      final bool mediaAsk = index == 2 && !controller.isMediaGranted;
      final bool notifAsk = index == 3 &&
          controller.notificationRequired &&
          !controller.isNotificationGranted;

      late final String label;
      late final VoidCallback? onPressed;
      if (isLast) {
        label = l10n.onboardingGetStarted;
        onPressed = busy ? null : controller.complete;
      } else if (mediaAsk) {
        label = l10n.permissionGrantButton;
        onPressed = busy ? null : controller.permission.requestMedia;
      } else if (notifAsk) {
        label = l10n.permissionGrantButton;
        onPressed = busy ? null : controller.permission.requestNotification;
      } else {
        label = l10n.onboardingNext;
        onPressed = busy ? null : controller.next;
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nokta göstergesi: etkin nokta hap biçiminde uzar.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < OnboardingController.totalPages; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    key: ValueKey('onboarding_dot_$i'),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: i == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('onboarding_primary'),
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      );
    });
  }
}
