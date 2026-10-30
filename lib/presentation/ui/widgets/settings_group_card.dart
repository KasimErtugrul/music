import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';

/// Gün 12: ayar gruplarının ortak kart bileşeni.
///
/// Tek tasarım dili: surfaceContainerLow yüzeyi + 16 radius + kenarlardan
/// kırpılmış satırlar. SettingsHomePage'deki özel `_NavCard` bu bileşene
/// devredildi; Gün 13'ün sayfa yeniden düzeni de aynı kartı kullanacak.
///
/// [title] verilirse kartın üstünde bölüm başlığı (SettingsSectionHeader)
/// çizilir; verilmezse yalnızca kart yüzeyi döner.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) SettingsSectionHeader(title: title!),
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}