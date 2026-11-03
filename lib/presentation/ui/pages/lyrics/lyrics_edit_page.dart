import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/lyrics_controller.dart';

/// Bulgu 6: söz ekleme/düzenleme sayfası. Şarkı seçenekler menüsünden ve
/// söz görüntüleyiciden açılır. Kaydet anında DB'ye yazılır (upsert);
/// metin boşaltılıp kaydedilirse söz silinir.
class LyricsEditPage extends StatefulWidget {
  const LyricsEditPage({super.key, required this.song, this.initialContent});

  final SongModel song;
  final String? initialContent;

  static Future<void> show(BuildContext context, SongModel song) async {
    final ctrl = Get.find<LyricsController>();
    final initial = ctrl.contentOf(song.id) ?? await ctrl.loadFor(song.id);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LyricsEditPage(song: song, initialContent: initial),
      ),
    );
  }

  @override
  State<LyricsEditPage> createState() => _LyricsEditPageState();
}

class _LyricsEditPageState extends State<LyricsEditPage> {
  late final TextEditingController _text;
  bool _saving = false;

  bool get _isLrc => LyricsController.looksLikeLrc(_text.text);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialContent ?? '');
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<LyricsController>();
    await ctrl.save(widget.song.id, _text.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lyricsSaved)),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<LyricsController>();
    await ctrl.remove(widget.song.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lyricsDeleted)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasExisting = widget.initialContent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lyricsEditTitle),
        actions: [
          if (hasExisting)
            IconButton(
              tooltip: l10n.lyricsDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.song.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // LRC imleci: içerik zaman damgalı satırlar içeriyorsa
                // görüntüleyicide eşzamanlı vurgu açılacağını bildirir.
                if (_isLrc)
                  Tooltip(
                    message: l10n.lyricsSyncedBadge,
                    child: Chip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text(l10n.lyricsSyncedBadge),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _text,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: l10n.lyricsHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(l10n.lyricsSave),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
