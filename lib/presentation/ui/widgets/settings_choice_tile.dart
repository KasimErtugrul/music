import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/settings_info_sheet.dart';

/// Seçim (tek seçimli) ayar satırı — Gün 12'de yeniden yazıldı.
///
/// KARAR (Gün 12): `DropdownButton` kaldırıldı. Sunum seçenek sayısına
/// göre otomatik seçilir:
/// - 3 veya daha az seçenek → satırın altında [SegmentedButton]; tüm
///   seçenekler görünür, tek dokunuşla seçilir.
/// - 4 veya daha fazla seçenek → satır dokunulduğunda alt sayfada (bottom
///   sheet) tek seçimli [RadioListTile] listesi; satırın sağında geçerli
///   değer gösterilir.
///
/// API değişmedi (title/subtitle/value/options/labelOf/onChanged): mevcut
/// çağrı yerleri aynen derlenir (geriye dönük uyumluluk).
///
/// Gün 16: [info] verilirse her iki sunumda da başlığın/satırın yanına
/// [SettingsInfoBadge] eklenir. Bölümlü sunumda rozet başlık satırındadır
/// (Semantics `container` olduğu için çocuk düğüm erişilebilir kalır);
/// alt sayfalı sunumda rozet satır Semantics'ının DIŞINDA durur ki
/// `excludeSemantics` etiketi rozeti yutmasın.
///
/// Erişilebilirlik: her iki sunum da ekran okuyucuya ayarın adını, alt
/// yazısını ve (satır sunumunda) geçerli değeri tek etikette bildirir.
/// Segment yüksekliği M3 varsayılanı 40 dp yerine 48 dp'dir (dokunma
/// hedefi); alt sayfa satırları ListTile sayesinde 56 dp'dir.
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.info,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  /// Ayarın ne işe yaradığını anlatan metin; verilirse bilgi balonu
  /// düğmesi çizilir (Gün 16).
  final String? info;

  @override
  Widget build(BuildContext context) {
    if (options.length <= 3) {
      return _SegmentedChoice<T>(
        title: title,
        subtitle: subtitle,
        value: value,
        options: options,
        labelOf: labelOf,
        onChanged: onChanged,
        info: info,
      );
    }
    return _SheetChoice<T>(
      title: title,
      subtitle: subtitle,
      value: value,
      options: options,
      labelOf: labelOf,
      onChanged: onChanged,
      info: info,
    );
  }
}

/// ≤3 seçenek: satır içi [SegmentedButton].
class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.info,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      // Grup kapsayıcısı: segmentler tek tek okunur ama grup, ayarın adıyla
      // tanımlanır. `container` çocukları dışlamaz; bilgi rozeti erişilebilir
      // kalır (Gün 16).
      container: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (info != null) SettingsInfoBadge(title: title, info: info!),
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            SegmentedButton<T>(
              // Seçim işareti yerine dolgu rengi; uzun etiketlerde yer
              // kazanır.
              showSelectedIcon: false,
              selected: <T>{value},
              onSelectionChanged: (s) => onChanged(s.first),
              style: const ButtonStyle(
                // Dokunma hedefi: M3 varsayılan 40 dp → 48 dp.
                minimumSize: WidgetStatePropertyAll<Size>(Size(0, 48)),
              ),
              segments: <ButtonSegment<T>>[
                for (final o in options)
                  ButtonSegment<T>(
                    value: o,
                    label: Text(
                      labelOf(o),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// >3 seçenek: değer satırı + alt sayfada tek seçimli liste.
class _SheetChoice<T> extends StatelessWidget {
  const _SheetChoice({
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.info,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? info;

  Future<void> _ac(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: Text(
                    title,
                    style: sheetTheme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: Text(
                      subtitle!,
                      style: sheetTheme.textTheme.bodySmall?.copyWith(
                        color: sheetTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      RadioGroup<T>(
                        groupValue: value,
                        onChanged: (v) {
                          if (v == null) return;
                          Navigator.of(sheetContext).pop();
                          onChanged(v);
                        },
                        child: Column(
                          children: <Widget>[
                            for (final o in options)
                              RadioListTile<T>(
                                value: o,
                                title: Text(labelOf(o)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget buildTile() {
      final listTile = ListTile(
        title: Text(
          title,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                labelOf(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
        onTap: () => _ac(context),
      );
      return Semantics(
        // Satır tek düğüm: başlık + alt yazı etiketi, geçerli değer `value`
        // alanında, dokunma eylemi Semantics üzerinde bildirilir.
        excludeSemantics: true,
        button: true,
        label: subtitle == null ? title : '$title. $subtitle',
        value: labelOf(value),
        onTap: () => _ac(context),
        child: listTile,
      );
    }

    // Gün 16: bilgi rozeti satır Semantics'ının DIŞINDA durur
    // (excludeSemantics rozetin düğümünü yutmasın diye).
    if (info == null) return buildTile();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: buildTile()),
        SettingsInfoBadge(title: title, info: info!),
      ],
    );
  }
}
