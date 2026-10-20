import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';

/// İzin sayfası. Düzen tasarım paketindeki "açılış depolama izinleri"
/// ekranını izler; profil avatarı, ham izin adı ve sürüm rozeti uygulanmadı
/// (şartname dışı).
class PermissionPage extends GetView<PermissionController> {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 24),
                Center(
                  child: ExcludeSemantics(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.graphic_eq,
                        size: 36,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.permissionTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.permissionSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _MediaCard(controller: controller),
                const SizedBox(height: 12),
                Obx(
                  () => controller.showNotificationCard
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationCard(controller: controller),
                        )
                      : const SizedBox.shrink(),
                ),
                Obx(
                  () => controller.media.value.isGranted
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton(
                            onPressed: controller.continueToApp,
                            child: Text(l10n.permissionContinueButton),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                _InfoCard(
                  icon: Icons.verified_user_outlined,
                  title: l10n.permissionPrivacyTitle,
                  body: l10n.permissionPrivacyBody,
                  surfaceColor: scheme.surfaceContainerLowest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.controller});

  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Obx(() {
      final status = controller.media.value;
      final requested = controller.mediaRequested.value;
      final busy = controller.busy.value;

      if (status == AppPermissionStatus.granted) {
        return _InfoCard(
          icon: Icons.check_circle_outline,
          title: l10n.permissionMediaTitle,
          body: l10n.permissionGrantedLabel,
        );
      }
      if (status == AppPermissionStatus.permanentlyDenied) {
        return _InfoCard(
          icon: Icons.shield_outlined,
          title: l10n.permissionPermanentlyDeniedTitle,
          body: l10n.permissionPermanentlyDeniedDescription,
          isError: true,
          action: FilledButton.tonalIcon(
            onPressed: controller.openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(l10n.permissionOpenSettingsButton),
          ),
        );
      }
      return _InfoCard(
        icon: requested ? Icons.error_outline : Icons.library_music_outlined,
        title: requested
            ? l10n.permissionDeniedTitle
            : l10n.permissionMediaTitle,
        body: requested
            ? l10n.permissionDeniedDescription
            : l10n.permissionMediaDescription,
        isError: requested,
        action: FilledButton.icon(
          onPressed: busy ? null : controller.requestMedia,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(l10n.permissionGrantButton),
        ),
      );
    });
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.controller});

  final PermissionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final permanent =
          controller.notification.value == AppPermissionStatus.permanentlyDenied;
      final busy = controller.busy.value;
      return _InfoCard(
        icon: Icons.notifications_active_outlined,
        title: l10n.permissionNotificationTitle,
        badge: Text(
          l10n.permissionNotificationBadge,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        body: l10n.permissionNotificationDescription,
        trailing: IconButton(
          tooltip: l10n.commonClose,
          onPressed: controller.dismissNotification,
          icon: const Icon(Icons.close),
        ),
        action: permanent
            ? TextButton.icon(
                onPressed: controller.openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(l10n.permissionOpenSettingsButton),
              )
            : TextButton(
                onPressed: busy ? null : controller.requestNotification,
                child: Text(l10n.permissionGrantButton),
              ),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.isError = false,
    this.badge,
    this.trailing,
    this.action,
    this.surfaceColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;
  final Widget? badge;
  final Widget? trailing;
  final Widget? action;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconBackground =
        isError ? scheme.errorContainer : scheme.secondaryContainer;
    final iconForeground =
        isError ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Card(
      elevation: 0,
      color: surfaceColor ?? scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    color: iconBackground,
                  ),
                  child: Icon(icon, color: iconForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: isError ? scheme.error : scheme.onSurface,
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: action,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
