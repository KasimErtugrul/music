import 'package:flutter/material.dart';

/// Gün 12: ayar satırının ortak yüzü (tek tasarım dili).
///
/// - Başlık/alt açıklama yerleşimi ListTile sözleşmesini izler; varsayılan
///   satır yüksekliği 48 dp dokunma hedefini karşılar ve ListTile kendi
///   içinde anlamsallığı (Semantics) birleştirir.
/// - Navigasyon affordansı dürüsttür: chevron yalnızca satır dokunulabilirken
///   (onTap != null) gösterilir; özel [trailing] verilirse o kazanır.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}