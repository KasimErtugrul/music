import 'package:flutter/material.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// Gün 16: ayar bilgi balonları — «kullanıcı bir ayarın ne işe yaradığını
/// bilmemeli asla» ilkesinin arayüz karşılığı.
///
/// İki parçadan oluşur:
/// - [SettingsInfoBadge]: satırların başlığına eklenen küçük «(i)» düğmesi.
///   Satırın KENDİ eyleminden bağımsız bir dokunma hedefidir (GestureArena
///   içinde IconButton kazandığı için satırın onTap/anahtarı tetiklenmez).
/// - [SettingsInfoSheet]: düğmeye dokununca açılan alt sayfa; ayarın adını
///   başlık olarak alır, ne işe yaradığını cümleler hâlinde anlatır.
///
/// Kullanım: yalnızca belirgin olmayan, uygulamaya özel ayarlara bağlanır.
/// Açık/Koyu tema, dil, yazı tipi gibi evrensel ayarlara bilgi eklenmez
/// (bilgi gürültüsü olmasın); metinler ARB'de `xxxInfo` anahtarlarıdır ve
/// TR+EN ikilisi olarak tutulur.
class SettingsInfoBadge extends StatelessWidget {
  const SettingsInfoBadge({
    super.key,
    required this.title,
    required this.info,
  });

  /// Ayarın görünen adı — balonun başlığı olur (satırda zaten yazılıdır).
  final String title;

  /// Ayarın ne işe yaradığını anlatan metin (l10n'den gelir).
  final String info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tooltip = AppLocalizations.of(context).settingsInfoTooltip;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      iconSize: 20,
      onPressed: () =>
          SettingsInfoSheet.show(context, title: title, message: info),
      icon: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
    );
  }
}

/// Ayar açıklaması alt sayfası: sürükleme tutamacı + ikonlu başlık + gövde
/// metni + Tamam düğmesi. Uzun metinlerde kaydırılabilir; yükseklik ekranın
/// %85'i ile sınırlıdır.
class SettingsInfoSheet extends StatelessWidget {
  const SettingsInfoSheet({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  /// Satırlardan tek çağrı noktası: [showDragHandle] M3 alt sayfa dilini
  /// izler (uygulamadaki diğer seçim alt sayfalarıyla aynı).
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          SettingsInfoSheet(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonOk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
