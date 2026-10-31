import 'package:flutter/material.dart';

/// Tek satırlık ayar/gezinme döşemesi — Gün 12 tasarım dili.
///
/// Kart içindeki eylem/gezinme satırları için ortak görünüm: başlık
/// bodyLarge/w600, alt yazı bodySmall/onSurfaceVariant, satır yüksekliği
/// ListTile sayesinde 56 dp (48 dp dokunma hedefinin üzerinde).
///
/// Erişilebilirlik: satır tek bir Semantics düğümü olarak okunur (başlık +
/// alt yazı); `button` işareti ve dokunma eylemi Semantics üzerinde
/// bildirilir, alt düğümler hariç tutulur ki ekran okuyucu aynı bilgiyi
/// iki kez okumasın.
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: subtitle == null ? title : '$title. $subtitle',
      onTap: onTap,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
        trailing: trailing ??
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
