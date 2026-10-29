// Aşama 6: Yedekleme sayfasının otomatik yedekleme bölümü.
//
// AutoBackupController InitialBinding'de permanent kayıtlıdır; widget
// testlerinde dışarıdan gerçek denetleyici (sahte repo'larla) enjekte
// edilebilir. Stil, backup_page.dart'ın M3 kart dilini izler:
// surfaceContainerLow zemin, 16 yarıçap, bölüm ikonu + açıklama.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';

class AutoBackupSection extends StatelessWidget {
  const AutoBackupSection({super.key, this.controller});

  final AutoBackupController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = controller ?? Get.find<AutoBackupController>();

    Future<void> runNow() async {
      final ok = await ctrl.runNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ok ? l10n.autoBackupRunDone : l10n.autoBackupRunError),
        ),
      );
    }

    Future<void> confirmRestore(AutoBackupEntry entry) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.autoBackupRestoreConfirmTitle),
          content: Text(
            l10n.autoBackupRestoreConfirmMessage(
              _formatTimestamp(entry.createdAt),
            ),
          ),
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
      if (ok != true) return;
      final done = await ctrl.restore(entry);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            done ? l10n.autoBackupRestoreDone : l10n.autoBackupRestoreError,
          ),
        ),
      );
    }

    Future<void> confirmDelete(AutoBackupEntry entry) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.autoBackupDeleteConfirmTitle),
          content: Text(l10n.autoBackupDeleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.backupCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.autoBackupDelete),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ctrl.deleteBackup(entry);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.autoBackupDeleteDone)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() {
        final active = ctrl.enabled.value;
        final busy = ctrl.isWorking.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Başlık ---
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings_backup_restore,
                      size: 26, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.autoBackupSectionTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.autoBackupSectionDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            // --- Aç/Kapa anahtarı ---
            // Dekore Container içinde ListTile ailesi, en yakın Material
            // atasına boyanır: bu Material olmadan debug modunda
            // 'ListTile background color or ink splashes may be invisible'
            // assertion'ı ateşlenir ve dokunma sıçraması görünmez olur.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: busy ? null : (v) => ctrl.setEnabled(v),
                title: Text(l10n.autoBackupSwitch,
                    style: theme.textTheme.titleSmall),
              ),
            ),
            // --- Sıklık ---
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                l10n.autoBackupFrequencyLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: AutoBackupFrequency.daily,
                    label: Text(l10n.autoBackupDaily),
                    icon: const Icon(Icons.today, size: 18),
                  ),
                  ButtonSegment(
                    value: AutoBackupFrequency.weekly,
                    label: Text(l10n.autoBackupWeekly),
                    icon: const Icon(Icons.date_range, size: 18),
                  ),
                ],
                selected: {ctrl.frequency.value},
                onSelectionChanged:
                    active ? (s) => ctrl.setFrequency(s.first) : null,
              ),
            ),
            const SizedBox(height: 12),
            // --- Saklanacak yedek sayısı ---
            Text(
              l10n.autoBackupKeep,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: <ButtonSegment<int>>[
                  for (final k in AutoBackupController.keepChoices)
                    ButtonSegment<int>(value: k, label: Text('$k')),
                ],
                selected: {ctrl.keepCount.value},
                onSelectionChanged:
                    active ? (s) => ctrl.setKeepCount(s.first) : null,
              ),
            ),
            const SizedBox(height: 16),
            // --- Şimdi yedekle + son çalışma ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          active && !busy ? () => runNow() : null,
                      icon: const Icon(Icons.backup, size: 20),
                      label: Text(l10n.autoBackupRunNow),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ctrl.lastRunAt.value == null
                  ? l10n.autoBackupNeverRun
                  : l10n.autoBackupLastRun(
                      _formatTimestamp(ctrl.lastRunAt.value!),
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            // --- Kayıtlı yedekler ---
            Text(
              l10n.autoBackupListTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            if (ctrl.backups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  l10n.autoBackupEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final entry in ctrl.backups)
                _BackupRow(
                  entry: entry,
                  title: _formatTimestamp(entry.createdAt),
                  subtitle: l10n.autoBackupSize(
                    (entry.sizeBytes / 1024).round(),
                  ),
                  onRestore: busy ? null : () => confirmRestore(entry),
                  onDelete: busy ? null : () => confirmDelete(entry),
                ),
          ],
        );
      }),
    );
  }

  /// Yerel/loopoloji-bağımsız sayısal biçim: 30.01.2026 12:45.
  String _formatTimestamp(DateTime d) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}.${d.year} ${p(d.hour)}:${p(d.minute)}';
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.entry,
    required this.title,
    required this.subtitle,
    required this.onRestore,
    required this.onDelete,
  });

  final AutoBackupEntry entry;
  final String title;
  final String subtitle;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_outlined,
                size: 19, color: cs.onSurfaceVariant),
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
          IconButton(
            tooltip: l10n.backupOverwrite,
            onPressed: onRestore,
            icon: const Icon(Icons.restore, size: 22),
          ),
          IconButton(
            tooltip: l10n.autoBackupDelete,
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline,
                size: 22, color: cs.error),
          ),
        ],
      ),
    );
  }
}
