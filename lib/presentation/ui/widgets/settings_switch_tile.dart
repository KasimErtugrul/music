import 'package:flutter/material.dart';

/// Gün 12: aç/kapa ayarının ortak yüzü (tek tasarım dili).
///
/// SwitchListTile sözleşmesi korunur: başlık + alt açıklama (l10n)
/// yerleşimi ListTile ailesiyle aynıdır, varsayılan satır yüksekliği
/// 48 dp dokunma hedefini karşılar ve SwitchListTile kendi içinde
/// anlamsallığı (Semantics: başlık + değer) birleştirir.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}