import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/settings_info_sheet.dart';

/// Tek satırlık ayar/gezinme döşemesi — Gün 12 tasarım dili.
///
/// Kart içindeki eylem/gezinme satırları için ortak görünüm: başlık
/// bodyLarge/w600, alt yazı bodySmall/onSurfaceVariant, satır yüksekliği
/// ListTile sayesinde 56 dp (48 dp dokunma hedefinin üzerinde).
///
/// Gün 16: [info] verilirse satırın sağında (chevron'dan önce) bir
/// [SettingsInfoBadge] çizilir. Bilgi düğmesi Semantics dışında tutulur:
/// satırın `excludeSemantics` etiketi yalnız satır metnini kapsasın diye
/// rozet, satırın DIŞINDA Expanded'lı bir Row ile yerleştirilir — aksi
/// halde ekran okuyucu bilgi düğmesini hiç duymazdı.
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
    this.info,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Ayarın ne işe yaradığını anlatan metin; verilirse satır sonunda
  /// bilgi balonu düğmesi çizilir (Gün 16).
  final String? info;

  Widget _rowTrailing(ThemeData theme) =>
      trailing ?? Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final listTile = ListTile(
      leading: leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
      trailing: _rowTrailing(theme),
      onTap: onTap,
    );

    final row = Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: subtitle == null ? title : '$title. $subtitle',
      onTap: onTap,
      child: listTile,
    );

    // Gün 16: bilgi rozeti satır Semantics'ının DIŞINDA durur; satırın
    // excludeSemantics etiketi rozetin ekran okuyucu düğümünü yutmasın.
    if (info == null) return row;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: row),
        SettingsInfoBadge(title: title, info: info!),
      ],
    );
  }
}
