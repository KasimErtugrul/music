import 'package:flutter/material.dart';
import 'package:resonance/presentation/ui/widgets/settings_info_sheet.dart';

/// Anahtar (switch) ayar satırı — Gün 12 tasarım dili.
///
/// Tüm ayar satırları gibi en az 48 dp dokunma hedefiyle çizilir
/// (SwitchListTile varsayılanı 56 dp); satırın herhangi bir yerine
/// dokunmak anahtarı değiştirir.
///
/// Gün 16: [info] verilirse başlığın yanına [SettingsInfoBadge] eklenir;
/// balon düğmesi kendi dokunmasını yuttuğu için anahtar tetiklenmez.
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
    this.info,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Gün 20.1: null geçilirse anahtar devre dışı çizilir (SwitchListTile
  /// davranışı). Motoru kurulu olmayan yüzeylerde — örn. sayfayı
  /// binding'siz pompalayan widget testleri — ayar dokunulamaz olur;
  /// uygulamada InitialBinding her zaman controller kurduğu için bu yol
  /// üretilmez.
  final ValueChanged<bool>? onChanged;

  /// Ayarın ne işe yaradığını anlatan metin; verilirse başlık yanında
  /// bilgi balonu düğmesi çizilir (Gün 16).
  final String? info;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: info == null
          ? Text(title)
          : Row(
              children: [
                Expanded(child: Text(title)),
                SettingsInfoBadge(title: title, info: info!),
              ],
            ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}