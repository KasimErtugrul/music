import 'package:flutter/material.dart';

/// Gün 12: seçim ayarı kutucuğunun tek tasarım dili.
///
/// İki yüz, tek sözleşme:
/// - 3 veya daha az seçenek → [SegmentedButton]: başlık + alt açıklama
///   üstte, tam genişlik segment satırı altta. Segment yüksekliği 48 dp'dir
///   (dokunma hedefi); segment grubu [Semantics] etiketi olarak ayar adını
///   taşır. Uzun etiketler satır taşması yerine üç nokta ile kırpılır.
/// - 3'ten fazla seçenek → [ListTile]; mevcut değer satırda kapalı bilgi
///   olarak okunur, dokununca alt sayfada radyo listesi ([RadioGroup] +
///   [RadioListTile], satır yüksekliği 48 dp+) açılır.
///
/// DropdownButton bu bileşenden Gün 12 ile kaldırıldı; API
/// (title/value/options/labelOf/onChanged/subtitle) aynen korunmuştur.
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.length <= 3) {
      return _SegmentedChoice<T>(tile: this);
    }
    return _SheetChoice<T>(tile: this);
  }
}

/// ≤3 seçenek yüzü: M3 SegmentedButton.
class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({required this.tile});

  final SettingsChoiceTile<T> tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tile.title, style: theme.textTheme.bodyLarge),
          if (tile.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              tile.subtitle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          // Ayar adı, segment grubunun erişilebilirlik etiketidir.
          Semantics(
            label: tile.title,
            child: SegmentedButton<T>(
              selected: <T>{
                if (tile.options.contains(tile.value)) tile.value,
              },
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) tile.onChanged(selection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                // Dokunma hedefi: segment yüksekliği >= 48 dp.
                minimumSize: const Size(0, 48),
              ),
              segments: [
                for (final option in tile.options)
                  ButtonSegment(
                    value: option,
                    label: Text(
                      tile.labelOf(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// >3 seçenek yüzü: kapalı bilgi + alt sayfa radyo listesi.
class _SheetChoice<T> extends StatelessWidget {
  const _SheetChoice({required this.tile});

  final SettingsChoiceTile<T> tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(tile.title),
      subtitle: tile.subtitle != null ? Text(tile.subtitle!) : null,
      // Gün 12: mevcut değer, çok seçenekli yüzeyde satırda okunur.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tile.labelOf(tile.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () => _showOptionsSheet(context),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(tile.title, style: theme.textTheme.titleMedium),
            ),
            if (tile.subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  tile.subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            // Gün 12: radyo listesi RadioGroup ile yönetilir — klasik
            // RadioListTile.groupValue/onChanged yolu v3.32'de önerilmiyor.
            RadioGroup<T>(
              groupValue: tile.value,
              onChanged: (selected) {
                Navigator.pop(sheetCtx);
                if (selected != null) tile.onChanged(selected);
              },
              child: Column(
                children: [
                  for (final option in tile.options)
                    RadioListTile<T>(
                      value: option,
                      title: Text(tile.labelOf(option)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}