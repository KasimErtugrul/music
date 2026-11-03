import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// Alt gezinmedeki beş sekmenin (Ana Sayfa, Kitaplık, Listeler, Ara,
/// Ayarlar) ortak marka üst bandı: «≡ Resonance» başlığı.
///
/// Neden kopyala-yapıştır değil de paylaşılan widget? Marka başlığı tek
/// bir yerde tanımlanır: ikon/renk/yazı değişikliği beş sayfaya aynı
/// anda yansır ve sayfalar arasında tutarsızlık teknik olarak imkânsız
/// hâle gelir. (Kopyala-yapıştır yaklaşımda beş bağımsız AppBar zamanla
/// sapar — ilk bozulma zaten yaşandı: Kitaplık «Kütüphane + Yerel»
/// rozeti, Listeler/Ayarlar düz metin, Ara ise gövde içi taklit başlık
/// çiziyordu.)
///
/// Neden `AppBar` kalıtımı? Sarmalayıcı (`StatelessWidget` + içte ikinci
/// bir `AppBar`) yazılsaydı Scaffold sarmalayıcının raporladığı yüksekliği
/// kullanırken iç AppBar'ın `bottom` düzeniyle çakışırdı (alt bölge 0
/// yüksekliğe düşüyordu — testle yakalandı). Widget doğrudan `AppBar`
/// olduğundan Scaffold gerçek `preferredSize`'ı (kToolbarHeight + alt
/// bölge) görür; state ise marka başlığını enjekte edip kalan her şeyi
/// AppBar'ın kendi düzenine bırakır. Sekmeye özgü içerik (Kitaplık'ın
/// eylem düğmeleri ve sekme hapları) [actions] ve [bottom] ile bu
/// bandın İÇİNE geçer; başlık kısmı asla sayfaya bırakılmaz.
class ResonanceAppBar extends AppBar {
  // AppBar kurucusu Flutter'da const olmadığı için bu kurucu da const
  // olamaz; sayfalarda `ResonanceAppBar()` (const'suz) kullanılır.
  ResonanceAppBar({super.key, super.actions, super.bottom})
    : super(titleSpacing: 20);

  @override
  ResonanceAppBarState createState() => ResonanceAppBarState();
}

class ResonanceAppBarState extends State<ResonanceAppBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.appName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: widget.actions,
      bottom: widget.bottom,
    );
  }
}
