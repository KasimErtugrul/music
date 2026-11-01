import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/onboarding_controller.dart';
import 'package:resonance/presentation/ui/widgets/app_monogram.dart';

/// Gün 18: onboarding'in 5 adımının içerik görünümleri.
///
/// Ortak tasarım sözleşmesi:
/// - Tüm adımlar `OnboardingStepScaffold` içinde kaydırılabilir; dar
///   ekranlarda içerik asla taşmaz.
/// - İzin durumlarının TEK kaynağı `OnboardingController.permission`
///   (kalıcı PermissionController); hiçbir adım yerel durum tutmaz.
/// - Renkler yalnızca Theme.colorScheme üzerinden; açık/koyu ve dinamik
///   renk tema değişimlerinde adımlar kendiliğinden uyar.

const double _kStepMaxWidth = 480;

/// Adım iskeleti: kaydırılabilir gövde; yatay 24 / dikey 20 dolgu,
/// 480 px okuma genişliği sınırı.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('onboarding_step_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kStepMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

// ========== ADIM 1: KARŞILAMA ==========

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      children: [
        const SizedBox(height: 24),
        // Aura + monogram: izin sayfasındaki hero ile aynı imza.
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AppMonogram(
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sürüm rozeti: izin sayfasındakiyle aynı anahtar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq,
                  size: 13, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.offlineCoreBadge('1.0.0'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.onboardingWelcomeTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.onboardingWelcomeBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ========== ADIM 2: ÖZELLİKLER ==========

class OnboardingFeaturesStep extends StatelessWidget {
  const OnboardingFeaturesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final features = <(IconData, String, String)>[
      (
        Icons.library_music_outlined,
        l10n.onboardingFeatureLibraryTitle,
        l10n.onboardingFeatureLibraryDesc,
      ),
      (
        Icons.equalizer,
        l10n.onboardingFeatureSoundTitle,
        l10n.onboardingFeatureSoundDesc,
      ),
      (
        Icons.lyrics,
        l10n.onboardingFeatureLyricsTitle,
        l10n.onboardingFeatureLyricsDesc,
      ),
      (
        Icons.palette_outlined,
        l10n.onboardingFeaturePersonalizeTitle,
        l10n.onboardingFeaturePersonalizeDesc,
      ),
    ];

    return OnboardingStepScaffold(
      children: [
        _StepHeader(
          icon: Icons.auto_awesome,
          title: l10n.onboardingFeaturesTitle,
        ),
        const SizedBox(height: 16),
        for (final (icon, title, desc) in features) ...[
          _FeatureRow(icon: icon, title: title, desc: desc),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ========== ADIM 3: MÜZİK (MEDYA) İZNİ ==========

class OnboardingMediaStep extends StatelessWidget {
  const OnboardingMediaStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      children: [
        _StepHeader(
          icon: Icons.folder_open_outlined,
          title: l10n.onboardingMediaTitle,
          body: l10n.onboardingMediaBody,
        ),
        const SizedBox(height: 20),
        Obx(() {
          final status = controller.permission.media.value;
          final busy = controller.permission.busy.value;

          if (status.isGranted) {
            return _PermissionResultCard(
              icon: Icons.check_circle,
              iconColor: theme.colorScheme.primary,
              iconBg:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              title: l10n.permissionMediaTitle,
              subtitle: l10n.permissionMediaSpec,
              description: l10n.permissionGrantedLabel,
              descriptionColor: theme.colorScheme.primary,
            );
          }

          if (status == AppPermissionStatus.permanentlyDenied) {
            return _PermissionResultCard(
              icon: Icons.gpp_maybe,
              iconColor: theme.colorScheme.error,
              iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              title: l10n.permissionPermanentlyDeniedTitle,
              titleColor: theme.colorScheme.error,
              description: l10n.permissionPermanentlyDeniedDescription,
              action: FilledButton.tonalIcon(
                onPressed: controller.permission.openSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.permissionOpenSettingsButton),
              ),
            );
          }

          return _PermissionResultCard(
            icon: Icons.library_music,
            iconColor: theme.colorScheme.primary,
            iconBg: theme.colorScheme.surfaceContainerHighest,
            title: l10n.permissionMediaTitle,
            subtitle: l10n.permissionMediaSpec,
            description: l10n.permissionMediaDescription,
            action: FilledButton.icon(
              onPressed: busy ? null : controller.permission.requestMedia,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: Text(l10n.permissionGrantButton),
            ),
          );
        }),
      ],
    );
  }
}

// ========== ADIM 4: BİLDİRİM İZNİ ==========

class OnboardingNotificationStep extends StatelessWidget {
  const OnboardingNotificationStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      children: [
        _StepHeader(
          icon: Icons.notifications_active,
          title: l10n.onboardingNotificationTitle,
          body: l10n.onboardingNotificationBody,
        ),
        const SizedBox(height: 20),
        Obx(() {
          final required = controller.notificationRequired;
          final status = controller.permission.notification.value;
          final busy = controller.permission.busy.value;

          // Android 13+ gerektiriyorsa gerçek durum kartı; gerekmiyorsa
          // (API < 33) bilgilendirici kart: aynı 5 sayfa korunur.
          if (!required) {
            return _PermissionResultCard(
              icon: Icons.notifications_active,
              iconColor: theme.colorScheme.secondary,
              iconBg: theme.colorScheme.surfaceContainerHighest,
              title: l10n.permissionNotificationTitle,
              badge: l10n.permissionNotificationBadge,
              description: l10n.onboardingNotificationNotRequired,
            );
          }

          if (status.isGranted) {
            return _PermissionResultCard(
              icon: Icons.check_circle,
              iconColor: theme.colorScheme.primary,
              iconBg:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              title: l10n.permissionNotificationTitle,
              badge: l10n.permissionNotificationBadge,
              description: l10n.permissionGrantedLabel,
              descriptionColor: theme.colorScheme.primary,
            );
          }

          if (status == AppPermissionStatus.permanentlyDenied) {
            return _PermissionResultCard(
              icon: Icons.notifications_off_outlined,
              iconColor: theme.colorScheme.error,
              iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              title: l10n.permissionNotificationTitle,
              badge: l10n.permissionNotificationBadge,
              description: l10n.permissionPermanentlyDeniedDescription,
              action: FilledButton.tonalIcon(
                onPressed: controller.permission.openSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.permissionOpenSettingsButton),
              ),
            );
          }

          return _PermissionResultCard(
            icon: Icons.notifications_active,
            iconColor: theme.colorScheme.secondary,
            iconBg: theme.colorScheme.surfaceContainerHighest,
            title: l10n.permissionNotificationTitle,
            badge: l10n.permissionNotificationBadge,
            description: l10n.permissionNotificationDescription,
            action: FilledButton.icon(
              onPressed:
                  busy ? null : controller.permission.requestNotification,
              icon: const Icon(Icons.notifications_outlined, size: 18),
              label: Text(l10n.permissionGrantButton),
            ),
          );
        }),
      ],
    );
  }
}

// ========== ADIM 5: ÖZET + GİZLİLİK ==========

class OnboardingSummaryStep extends StatelessWidget {
  const OnboardingSummaryStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      children: [
        _StepHeader(
          icon: Icons.task_alt,
          title: l10n.onboardingSummaryTitle,
          body: l10n.onboardingSummaryBody,
        ),
        const SizedBox(height: 20),
        Obx(
          () => _ChecklistRow(
            icon: controller.isMediaGranted
                ? Icons.check_circle
                : Icons.schedule,
            iconColor: controller.isMediaGranted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            title: l10n.permissionMediaTitle,
            status: controller.isMediaGranted
                ? l10n.permissionGrantedLabel
                : l10n.onboardingPermissionPending,
            statusColor: controller.isMediaGranted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => _ChecklistRow(
            icon: controller.isNotificationGranted
                ? Icons.check_circle
                : Icons.schedule,
            iconColor: controller.isNotificationGranted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            title: l10n.permissionNotificationTitle,
            badge: l10n.permissionNotificationBadge,
            status: controller.isNotificationGranted
                ? l10n.permissionGrantedLabel
                : l10n.onboardingPermissionPending,
            statusColor: controller.isNotificationGranted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _PrivacyBanner(
          title: l10n.permissionPrivacyTitle,
          body: l10n.permissionPrivacyBody,
        ),
      ],
    );
  }
}

// ========== ORTAK PARÇALAR ==========

/// Adım başlığı: ikon balonu + başlık (+ isteğe bağlı açıklama).
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          ),
          child: Icon(icon, size: 28, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

/// Özellik satırı: yuvarlak kare ikon + başlık + açıklama.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(icon, size: 22, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// İzin durum kartı: sonucun (verildi / kalıcı ret / bekleme) tek biçimi.
class _PermissionResultCard extends StatelessWidget {
  const _PermissionResultCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    this.titleColor,
    this.descriptionColor,
    this.subtitle,
    this.badge,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Color? titleColor;
  final String description;
  final Color? descriptionColor;
  final String? subtitle;
  final String? badge;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: descriptionColor ?? theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      ),
    );
  }
}

/// Özet satırı: durum ikonu + izin adı (+ rozet) + durum etiketi.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badge;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gizlilik bannerı: izin sayfasındakiyle aynı içerik anahtarları.
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainer,
            ),
            child: Icon(
              Icons.verified_user,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
