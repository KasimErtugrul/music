import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/backup_controller.dart';

/// Yedekleme ve geri yükleme — M3 tasarım güncellemesi:
/// - Üstte kapsam bilgi kartı (açıklama + "ses dosyaları dahil değildir" notu)
/// - "Yedeğe Dahil Edilenler" listesi: yedeğin GERÇEK kapsamı (çalma
///   listeleri, favoriler, özel temalar, ekolayzır preset'leri, ayarlar).
///   Tasarımdaki etkileşimli onay kutuları seçmeli yedekleme özelliği
///   içermediği için salt bilgilendiren işaretli liste olarak çizildi.
///   Çalma geçmişi (history) yedek kapsamında olmadığından listede yer almaz.
/// - "Dışa Aktar": büyük dolu düğme + son yedek zamanı satırı
///   (BackupController artık zamanı kalıcı tutar).
/// - "Geri Yükle": uyumluluk uyarı bandı + dosya seçme düğmesi. İçe aktarma
///   sonucu (başarı / sürüm uyuşmazlığı / hata) artık kullanıcıya net
///   bildirilir; artık sessiz geçiştirilmez.
/// - Tasarımdaki "Geçmiş Yedekleme Durumu" listesi bilinçli olarak
///   EKLENMEDİ: geçmiş yedek kayıtlarını saklayan bir veri yoktur; sahte
///   girdiler yerine gerçek işlemler korunmuştur.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = Get.find<BackupController>();

    Future<void> doExport() async {
      final ok = await ctrl.exportData(l10n);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.backupExportSuccess : l10n.backupExportError),
        ),
      );
    }

    Future<void> doImport() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupImportConfirmTitle),
          content: Text(l10n.backupImportConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.backupCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.backupOverwrite),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final status = await ctrl.importData(l10n);
      if (!context.mounted) return;
      // İptal: kullanıcı dosya seçmedi — bildirim göstermeye gerek yok.
      if (status == ImportStatus.cancelled) return;
      final message = switch (status) {
        ImportStatus.success => l10n.backupImportSuccess,
        ImportStatus.versionMismatch => l10n.backupVersionMismatch,
        ImportStatus.cancelled => '',
        ImportStatus.failure => l10n.backupImportError,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: Obx(() {
        final busy = ctrl.isLoading.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // --- Kapsam bilgi kartı (hero) ---
            _HeroCard(),
            const SizedBox(height: 16),

            // --- Yedeğe dahil edilenler (gerçek kapsam) ---
            _IncludedCard(),
            const SizedBox(height: 16),

            // --- Dışa Aktar ---
            _SectionLabel(
              label: l10n.backupExport.toUpperCase(),
              color: cs.primary,
              trailing: Obx(() {
                final at = ctrl.lastBackupAt.value;
                if (at == null) return const SizedBox.shrink();
                return Text(
                  l10n.backupLastExport(_formatTimestamp(at)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.backupCreateFileTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.backupFormatNote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.data_object,
                            size: 20, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: busy ? null : doExport,
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 22),
                      label: Text(
                        busy ? l10n.backupExport : l10n.backupCreateFileTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Geri Yükle ---
            _SectionLabel(
              label: l10n.backupImport.toUpperCase(),
              color: cs.secondary,
            ),
            const SizedBox(height: 6),
            // Uyarı bandı: üzerine yazma + uyumsuz sürüm davranışı.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 22, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupImportConfirmTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.backupImportConfirmMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onErrorContainer,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.backupImport,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.backupRestorePickFile,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.folder_open,
                            size: 20, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton.tonalIcon(
                      onPressed: busy ? null : doImport,
                      icon: const Icon(Icons.upload, size: 20),
                      label: Text(l10n.backupRestorePickFile),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Yerel/loopoloji-bağımsız sayısal biçim: 14.10.2024 21:40.
  String _formatTimestamp(DateTime d) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}.${d.year} ${p(d.hour)}:${p(d.minute)}';
  }
}

// ========== HERO KARTI ==========

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_sync,
                    size: 26, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.backupTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.backupDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupNoAudioNote,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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

// ========== KAPSAM LİSTESİ ==========

class _IncludedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupIncludedTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.backupIncludedSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _IncludedRow(
            icon: Icons.queue_music,
            iconColor: cs.primary,
            title: l10n.backupItemPlaylists,
            subtitle: l10n.backupItemPlaylistsDesc,
          ),
          _IncludedRow(
            icon: Icons.favorite,
            iconColor: cs.tertiary,
            title: l10n.backupItemFavorites,
            subtitle: l10n.backupItemFavoritesDesc,
          ),
          _IncludedRow(
            icon: Icons.palette,
            iconColor: cs.secondary,
            title: l10n.backupItemThemes,
            subtitle: l10n.backupItemThemesDesc,
          ),
          _IncludedRow(
            icon: Icons.equalizer,
            iconColor: cs.primary,
            title: l10n.backupItemEqualizer,
            subtitle: l10n.backupItemEqualizerDesc,
          ),
          _IncludedRow(
            icon: Icons.settings,
            iconColor: cs.onSurfaceVariant,
            title: l10n.backupItemSettings,
            subtitle: l10n.backupItemSettingsDesc,
          ),
        ],
      ),
    );
  }
}

class _IncludedRow extends StatelessWidget {
  const _IncludedRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Bilgilendiren işaret: kapsam sabittir, seçmeli yedek yoktur.
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.check, size: 15, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ========== BÖLÜM BAŞLIĞI ==========

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color, this.trailing});
  final String label;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
