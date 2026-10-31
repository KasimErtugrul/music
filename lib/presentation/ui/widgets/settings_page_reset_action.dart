import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// Gün 13: «Bu sayfayı varsayılana döndür» AppBar eylemi.
///
/// Ayarlar sayfalarının AppBar'ına konan ortak yıkıcı eylem: dokunulduğunda
/// onay diyaloğu açar, onaylanırsa [onReset] çalıştırılır ve resetDone
/// SnackBar'ı gösterilir. Sayfa kapsamı [onReset]'e aittir: her sayfa
/// yalnız KENDİ sayfasında yaşayan anahtarları sıfırlar (ör. Çalma sayfası
/// hız/perdeyi korur — PreferencesController.resetPlayback).
///
/// Gün 15: onay diyaloğu + sıfırlama + SnackBar zinciri [confirmAndRun]
/// statik yardımcısına alındı. Gün 6'daki «Tüm ayarları sıfırla» diyaloğu
/// (settings_home_page._confirmReset) ile bu widget aynı AlertDialog
/// desenini iki kez implement ediyordu; artık tek doğruluk kaynağıdır.
/// «Tümünü sıfırla» satırı farklı dizgeler kullanır (resetAll /
/// resetConfirm); [title], [content] ve [confirmLabel] bu yüzden
/// parametredir.
class SettingsPageResetAction extends StatelessWidget {
  const SettingsPageResetAction({super.key, required this.onReset});

  final Future<void> Function() onReset;

  /// Gün 15: ortak yıkıcı-eylem akışı. Onay diyaloğu (İptal TextButton +
  /// onay FilledButton — Gün 6 deseni), onay durumunda [onReset] ve
  /// resetDone SnackBar'ı. İptal edilirse [onReset] hiç çağrılmaz ve
  /// hiçbir geri bildirim çıkmaz (diskte de hiçbir şey değişmez; bu sözleşme
  /// Gün 13 widget testleriyle korunur).
  static Future<void> confirmAndRun(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required Future<void> Function() onReset,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.settings_backup_restore),
      tooltip: l10n.pageResetTooltip,
      onPressed: () => confirmAndRun(
        context,
        title: l10n.pageResetTooltip,
        content: l10n.pageResetConfirm,
        confirmLabel: l10n.pageResetTooltip,
        onReset: onReset,
      ),
    );
  }
}
