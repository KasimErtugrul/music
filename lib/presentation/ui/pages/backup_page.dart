import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/backup_controller.dart';

/// UI tasarım güncellemesi: yedekleme sayfası tasarım diline göre yeniden
/// düzenlendi — üstte bilgi kartı (kapsam açıklaması + ses dosyaları notu),
/// "Dışa Aktar" bölümü (dolgulu ana düğme), "Geri Yükle" bölümü (uyarı bandı
/// + ikincil düğme).
///
/// Tasarımdaki "Geçmiş Yedekleme Durumu" listesi bilinçli olarak EKLENMEDİ:
/// BackupController son yedek zamanını/konumunu kaydetmez; sahte geçmiş
/// girdileri yerine gerçek işlemler korunmuştur. Kontrolcünün export/import
/// mantığı (FilePicker + documents fallback + onay diyaloğu) aynen kalır.
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
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupExportSuccess)),
        );
      } else if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupExportError)),
        );
      }
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
                child: Text(l10n.backupCancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.backupOverwrite)),
          ],
        ),
      );
      if (confirm != true) return;

      final ok = await ctrl.importData(l10n);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? l10n.backupImportSuccess : l10n.backupImportError)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: Obx(() {
        final busy = ctrl.isLoading.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // --- Bilgi kartı (hero) ---
            Container(
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.cloud_sync,
                            color: cs.onSecondaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.backupTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.backupDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Gerçek kapsam notu: yedek yalnızca veritabanı + ayarları
                  // taşır; müzik dosyaları dahil değildir.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: cs.primary),
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
            ),

            // --- Dışa Aktar ---
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                l10n.backupExport,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : doExport,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(l10n.backupExport),
                  ),
                ],
              ),
            ),

            // --- Geri Yükle ---
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                l10n.backupImport,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Uyarı bandı: geri yükleme mevcut verilerin üzerine yazar.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 22, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.backupImportConfirmMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onErrorContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : doImport,
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.backupImport),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
