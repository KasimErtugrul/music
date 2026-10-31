import 'package:flutter/material.dart';

/// Anahtar (switch) ayar satırı — Gün 12 tasarım dili.
///
/// Tüm ayar satırları gibi en az 48 dp dokunma hedefiyle çizilir
/// (SwitchListTile varsayılanı 56 dp); satırın herhangi bir yerine
/// dokunmak anahtarı değiştirir.
///
/// Erişilebilirlik: SwitchListTile başlığı ve alt yazısı anahtarın
/// Semantics etiketine kendisi ekler (durum okunurken satır metni duyulur);
/// bu yüzden ayrıca etiket eklenmez.
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
