import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';

class PermissionPage extends GetView<PermissionController> {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
   // final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // 1. Geri butonu (varsa çalışır, ilk sayfada no-op)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),

                // 2. Hero section: monogram + sürüm rozeti + başlık + alt başlık
                _HeroSection(),

                const SizedBox(height: 28),

                // 3. Medya izin kartı
                _MediaPermissionCard(controller: controller),

                // 4. Bildirim izin kartı (yalnızca gerekliyse)
                Obx(
                  () => controller.showNotificationCard
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _NotificationPermissionCard(
                              controller: controller),
                        )
                      : const SizedBox.shrink(),
                ),

                // 5. Devam butonu (medya izni verildiyse)
                Obx(
                  () => controller.media.value.isGranted
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: controller.continueToApp,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(l10n.permissionContinueButton),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // 6. Gizlilik ve çevrimdışı taahhüt banner'ı
                _PrivacyBanner(
                  title: l10n.permissionPrivacyTitle,
                  body: l10n.permissionPrivacyBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== HERO SECTION ==========

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Ambient aura glow + monogram
        Stack(
          alignment: Alignment.center,
          children: [
            // Aura glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            // Monogram badge
            Container(
              width: 80,
              height: 80,
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
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CustomPaint(
                        painter: _MonogramPainter(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sürüm rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq,
                size: 13,
                color: theme.colorScheme.primary,
              ),
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
        const SizedBox(height: 12),

        // Başlık
        Text(
          '${l10n.appName} ${l10n.permissionTitle}',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),

        // Alt başlık
        Text(
          l10n.permissionSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ========== MEDIA PERMISSION CARD ==========

class _MediaPermissionCard extends StatelessWidget {
  const _MediaPermissionCard({required this.controller});
  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      final status = controller.media.value;
      final requested = controller.mediaRequested.value;
      final busy = controller.busy.value;

      if (status == AppPermissionStatus.granted) {
        return _Card(
          icon: Icons.check_circle,
          iconColor: theme.colorScheme.primary,
          iconBg: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          title: l10n.permissionMediaTitle,
          subtitle: l10n.permissionMediaSpec,
          description: l10n.permissionGrantedLabel,
          descriptionColor: theme.colorScheme.primary,
        );
      }

      if (status == AppPermissionStatus.permanentlyDenied) {
        return _Card(
          icon: Icons.gpp_maybe,
          iconColor: theme.colorScheme.error,
          iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
          title: l10n.permissionPermanentlyDeniedTitle,
          titleColor: theme.colorScheme.error,
          description: l10n.permissionPermanentlyDeniedDescription,
          action: FilledButton.tonalIcon(
            onPressed: controller.openSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(l10n.permissionOpenSettingsButton),
          ),
        );
      }

      return _Card(
        icon: Icons.library_music,
        iconColor: theme.colorScheme.primary,
        iconBg: theme.colorScheme.surfaceContainerHighest,
        title: requested
            ? l10n.permissionDeniedTitle
            : l10n.permissionMediaTitle,
        subtitle: requested ? null : l10n.permissionMediaSpec,
        titleColor: requested ? theme.colorScheme.error : null,
        description: requested
            ? l10n.permissionDeniedDescription
            : l10n.permissionMediaDescription,
        action: FilledButton.icon(
          onPressed: busy ? null : controller.requestMedia,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: Text(l10n.permissionGrantButton),
        ),
      );
    });
  }
}

// ========== NOTIFICATION PERMISSION CARD ==========

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({required this.controller});
  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Obx(() {
      final status = controller.notification.value;
      final busy = controller.busy.value;

      if (status == AppPermissionStatus.permanentlyDenied) {
        return _Card(
          icon: Icons.notifications_off_outlined,
          iconColor: theme.colorScheme.error,
          iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
          title: l10n.permissionNotificationTitle,
          badge: l10n.permissionNotificationBadge,
          description: l10n.permissionNotificationDescription,
          action: FilledButton.tonalIcon(
            onPressed: controller.openSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(l10n.permissionOpenSettingsButton),
          ),
        );
      }

      return _Card(
        icon: Icons.notifications_active,
        iconColor: theme.colorScheme.secondary,
        iconBg: theme.colorScheme.surfaceContainerHighest,
        title: l10n.permissionNotificationTitle,
        badge: l10n.permissionNotificationBadge,
        description: l10n.permissionNotificationDescription,
        trailing: Switch(
          value: status.isGranted,
          onChanged: busy
              ? null
              : (v) {
                  if (v && !status.isGranted) {
                    controller.requestNotification();
                  }
                },
        ),
      );
    });
  }
}

// ========== PRIVACY BANNER ==========

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

// ========== ORTAK KART ==========

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    this.titleColor,
    this.descriptionColor,
    this.badge,
    this.subtitle,
    this.trailing,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Color? titleColor;
  final String description;
  final Color? descriptionColor;
  final String? badge;

  /// Teknik etiket (ör. READ_MEDIA_AUDIO): başlığın altında küçük metin.
  final String? subtitle;
  final Widget? trailing;
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                ),
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
              if (trailing != null) trailing!,
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
            Align(
              alignment: Alignment.centerRight,
              child: action!,
            ),
          ],
        ],
      ),
    );
  }
}

// ========== MONOGRAM PAINTER ==========

class _MonogramPainter extends CustomPainter {
  _MonogramPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * s;

    // Headphone arch (cubic bezier)
    final arch = Path()
      ..moveTo(5 * s, 16 * s)
      ..cubicTo(5 * s, 9.925 * s, 9.925 * s, 5 * s, 16 * s, 5 * s)
      ..cubicTo(22.075 * s, 5 * s, 27 * s, 9.925 * s, 27 * s, 16 * s);
    canvas.drawPath(arch, strokePaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Sol kulaklık
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * s, 16 * s, 3.5 * s, 7.5 * s),
        Radius.circular(1.75 * s),
      ),
      fillPaint,
    );
    // Sağ kulaklık
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24.5 * s, 16 * s, 3.5 * s, 7.5 * s),
        Radius.circular(1.75 * s),
      ),
      fillPaint,
    );

    // Ses dalgaları
    final barPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2 * s;

    final barPaintThick = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * s;

    canvas.drawLine(
        Offset(11 * s, 18.5 * s), Offset(11 * s, 13.5 * s), barPaint);
    canvas.drawLine(
        Offset(14.5 * s, 21 * s), Offset(14.5 * s, 11 * s), barPaint);
    canvas.drawLine(
        Offset(18 * s, 23 * s), Offset(18 * s, 9 * s), barPaintThick);
    canvas.drawLine(
        Offset(21.5 * s, 19.5 * s), Offset(21.5 * s, 12.5 * s), barPaint);
  }

  @override
  bool shouldRepaint(covariant _MonogramPainter oldDelegate) =>
      oldDelegate.color != color;
}