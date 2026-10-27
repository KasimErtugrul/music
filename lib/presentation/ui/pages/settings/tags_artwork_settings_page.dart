import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

/// Etiketler ve kapak ayarları.
///
/// Görev 1.4: "Kapak önbelleğini temizle" düğmesi artık gerçek temizlik yapar.
/// Üç hedef birlikte silinir:
///   1) ArtworkImage'ın statik bayt LRU önbelleği (en fazla 200 giriş),
///   2) Flutter'ın genel görüntü önbelleği (decode edilmiş görseller),
///   3) Bildirim kapağı için main.dart'ta yazılan geçici notif_art klasörü.
/// Ana ekran widget'ının kapağı (widget_artwork.jpg) bilinçli olarak
/// KORUNUR: o dosya widget'ın tek kapağıdır; silinmesi widget'ta boş
/// kapağa yol açardı.
class TagsArtworkSettingsPage extends StatefulWidget {
  const TagsArtworkSettingsPage({super.key});

  @override
  State<TagsArtworkSettingsPage> createState() =>
      _TagsArtworkSettingsPageState();
}

class _TagsArtworkSettingsPageState extends State<TagsArtworkSettingsPage> {
  bool _busy = false;

  Future<void> _clearCache() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      // 1) ArtworkImage'ın statik bayt LRU önbelleği
      ArtworkImage.clearCache();

      // 2) Flutter genel görüntü önbelleği
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 3) Bildirim kapaklarının yazıldığı geçici klasör
      //    (path paketi pubspec'te yok; yol, main.dart'taki gibi birleştirilir)
      final tmp = await getTemporaryDirectory();
      final notifDir = Directory('${tmp.path}/notif_art');
      if (await notifDir.exists()) {
        await notifDir.delete(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.artworkCacheCleared)),
        );
      }
    } on Object catch (e) {
      // Dürüst hata bildirimi: işlem başarısızsa başarılı mesajı YALANMAMALI.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.clearArtworkCache}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsArtworkSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.cleaning_services),
            title: Text(l10n.clearArtworkCache),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }
}
