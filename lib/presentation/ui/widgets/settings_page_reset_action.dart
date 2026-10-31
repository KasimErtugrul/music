import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// Gün 13: «Bu sayfayı varsayılana döndür» AppBar eylemi.
///
/// Ayarlar sayfalarının AppBar'ına konan ortak yıkıcı eylem: dokunulduğunda
/// onay diyaloğu açar (İptal TextButton + onay FilledButton — Gün 6'daki
/// «Tüm ayarları sıfırla» diyaloğuyla aynı desen), onaylanırsa [onReset]
/// çalıştırılır ve resetDone SnackBar'ı gösterilir. Sayfa kapsamı [onReset]'e
/// aittir: her sayfa yalnız KENDİ sayfasında yaşayan anahtarları sıfırlar
/// (ör. Çalma sayfası hız/perdeyi korur — PreferencesController.resetPlayback).
class SettingsPageResetAction extends StatelessWidget {
  const SettingsPageResetAction({super.key, required this.onReset});

  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.settings_backup_restore),
      tooltip: l10n.pageResetTooltip,
      onPressed: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pageResetTooltip),
        content: Text(l10n.pageResetConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pageResetTooltip),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await onReset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.resetDone)),
    );
  }
}
