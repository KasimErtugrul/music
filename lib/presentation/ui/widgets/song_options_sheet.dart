import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/utils/share_helper.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/vault_controller.dart'; // YENİ (Gün 17)
import 'package:resonance/presentation/ui/pages/tag_viewer_page.dart';
import 'package:resonance/presentation/ui/widgets/playlist_picker_sheet.dart';
import 'package:resonance/presentation/ui/widgets/song_info_sheet.dart';

class SongOptionsSheet extends StatelessWidget {
  const SongOptionsSheet({super.key, required this.song});
  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet<void>(
      context: context,
      // Gün 17.6 taşma düzeltmesi: menü 9 satıra büyüdü («Kasaya ekle»);
      // varsayılan alt sayfa sınırı küçük ekranlarda yetmiyordu. Alt
      // sayfaya tam yükseklik hakkı verilir; yine de sığmazsa aşağıdaki
      // kaydırılabilir sarmalayıcı devreye girer.
      isScrollControlled: true,
      builder: (_) => SongOptionsSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = Get.find<PlayerController>();
    final favCtrl = Get.find<FavoriteController>();
    final theme = Theme.of(context);

    return SafeArea(
      // Kaydırılabilir sarmalayıcı: küçük ekran ya da büyük yazı tipi
      // ölçeğinde taşma yerine dikey kaydırma. Column min boyutta
      // kaldığı için büyük ekranlarda görünüm değişmez.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist ?? l10n.unknownArtist),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(l10n.playNext),
              onTap: () {
                player.playNext(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(l10n.addToQueue),
              onTap: () {
                player.addToQueue(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l10n.addToPlaylist),
              onTap: () {
                Navigator.pop(context);
                PlaylistPickerSheet.show(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(l10n.tagViewer),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => TagViewerPage(song: song));
              },
            ),
            Obx(() {
              final isFav = favCtrl.isFavorite(song.id);
              return ListTile(
                leading: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? theme.colorScheme.error : null,
                ),
                title: Text(isFav ? l10n.removeFromFavorites : l10n.addToFavorites),
                onTap: () {
                  favCtrl.toggle(song);
                  Navigator.pop(context);
                },
              );
            }),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.share),
              onTap: () {
                Navigator.pop(context);
                ShareHelper.shareSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.songInfo),
              onTap: () {
                Navigator.pop(context);
                SongInfoSheet.show(context, song);
              },
            ),
            // Gün 17 (Kasa): yıkıcı eylem en sonda, hata rengiyle. Şarkı
            // kütüphaneden/aramadan/çalmadan tamamen çekilir; dosyaya
            // dokunulmaz.
            ListTile(
              leading: Icon(Icons.gpp_bad, color: theme.colorScheme.error),
              title: Text(
                l10n.banSongAction,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmBan(context, song);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Gün 17: kasa onay diyaloğu. «Geçmişi de temizle» onay kutusu
  /// varsayılan açıktır — çalma geçmişi tablosu başlık anlık görüntüsü
  /// tuttuğu için şarkı kasaya alınınca geçmişi de silinmeden bırakılması
  /// bilgi sızdırır. Dosyanın kendisine dokunulmaz; metinde belirtilir.
  Future<void> _confirmBan(BuildContext context, SongModel song) async {
    final l10n = AppLocalizations.of(context);
    final vault = Get.find<VaultController>();
    var cleanHistory = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.banConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.banConfirmBody(song.title)),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: cleanHistory,
                onChanged: (v) =>
                    setDialogState(() => cleanHistory = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.banConfirmCleanHistory),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.banSongAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await vault.ban(song, cleanHistory: cleanHistory);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.banSongDone)),
    );
  }
}