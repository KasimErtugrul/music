import 'package:flutter/material.dart';

/// Ayar sayfalarının ortak grup kartı — tek tasarım dilinin kart bileşeni.
///
/// Gün 12: ayarlar ana sayfasındaki kategorik kartların (surface-container-
/// low + 16 radius + antiAlias kırpma) birebir karşılığıdır; artık tüm alt
/// ayar sayfaları da aynı kartı kullanır (eskiden her sayfa kendi ListTile
/// düz listesiyle "tasarım lehçesi" oluşturuyordu).
///
/// [SettingsSectionHeader] kartın ÜSTÜNDE başlık verir; kartın içine
/// [SettingsTile], [SettingsSwitchTile], [SettingsChoiceTile] veya sayfaya
/// özel satırlar girer.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Kart yüzeyinde dikey dizilen satırlar.
  final List<Widget> children;

  /// Varsayılan yalnızca dikey 8 boşluk; yatay boşluğu sayfanın
  /// ListView dolgusu verir (ayarlar ana sayfasıyla aynı ritim).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      // Gün 13: kart, satırlarına kendi Material'ını verir. ListTile
      // tabanlı döşemeler (SettingsTile/SwitchTile/ChoiceTile satırı)
      // mürekkeplerini en yakın Material atasına basar; bu Material yoksa
      // kartın renkli Container'ı hem dokunma vurgusunu gizler hem de
      // Flutter'ın «ListTile background color or ink splashes may be
      // invisible» debug doğrulamasını tetikler. Şeffaf Material, görünümü
      // değiştirmeden mürekkebi kart yüzeyine taşır.
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }
}
