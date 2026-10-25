import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/backup_controller.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<BackupController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.backupDesc, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(l10n.backupExport),
              onTap: () async {
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
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.backupImport),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.backupImportConfirmTitle),
                    content: Text(l10n.backupImportConfirmMessage),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.backupCancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.backupOverwrite)),
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
              },
            ),
          ],
        );
      }),
    );
  }
}