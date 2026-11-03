import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lrc/lrc.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/lyrics_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/pages/lyrics/lyrics_edit_page.dart';

/// Bulgu 6: söz görüntüleyici. Oynatıcıdaki sözler düğmesinden açılır.
///
/// * Düz metin: kaydırılabilir tek sütun.
/// * LRC (`[mm:ss.xx]` satırları): çalma konumuyla eşzamanlı vurgu;
///   aktif satır otomatik ortaya kaydırılır, dokunulan satır o anı arar.
/// * Söz yoksa: «ekle» çağrısıyla düzenleyiciye yönlendirir.
class LyricsViewPage extends StatefulWidget {
  const LyricsViewPage({super.key, required this.song});

  final SongModel song;

  static Future<void> show(BuildContext context, SongModel song) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => LyricsViewPage(song: song)),
      );

  @override
  State<LyricsViewPage> createState() => _LyricsViewPageState();
}

class _LyricsViewPageState extends State<LyricsViewPage> {
  late final LyricsController _ctrl;
  late final PlayerController _player;
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<LyricsController>();
    _player = Get.find<PlayerController>();
    _load();
  }

  Future<void> _load() async {
    final content = await _ctrl.loadFor(widget.song.id);
    if (!mounted) return;
    setState(() {
      _content = content;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l10n.lyricsEditTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await LyricsEditPage.show(context, widget.song);
              if (mounted) _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_content == null
              ? _EmptyLyrics(l10n: l10n, onAdd: () async {
                  await LyricsEditPage.show(context, widget.song);
                  if (mounted) _load();
                })
              : LyricsController.looksLikeLrc(_content!)
                  ? _SyncedLyricsView(
                      raw: _content!,
                      position: _player.position,
                      onTapSeek: (d) => _player.seek(d),
                      textStyle: theme.textTheme.bodyLarge ??
                          const TextStyle(fontSize: 16),
                      highlightStyle: (theme.textTheme.titleMedium ??
                              const TextStyle(fontSize: 18))
                          .copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _content!,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                      ),
                    )),
    );
  }
}

class _EmptyLyrics extends StatelessWidget {
  const _EmptyLyrics({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_quote,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.lyricsEmpty, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.lyricsAddAction),
          ),
        ],
      ),
    );
  }
}

/// LRC içeriği: satırlar zaman damgasına göre vurgulanır.
class _SyncedLyricsView extends StatefulWidget {
  const _SyncedLyricsView({
    required this.raw,
    required this.position,
    required this.onTapSeek,
    required this.textStyle,
    required this.highlightStyle,
  });

  final String raw;
  final Rx<Duration> position;
  final ValueChanged<Duration> onTapSeek;
  final TextStyle textStyle;
  final TextStyle highlightStyle;

  @override
  State<_SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<_SyncedLyricsView> {
  late final List<(Duration, String)> _lines;
  int _activeIndex = -1;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    final lrc = Lrc.parse(widget.raw);
    _lines = [
      for (final l in lrc.lyrics) (l.timestamp, l.lyrics),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexFor(Duration pos) {
    var idx = -1;
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].$1 <= pos) idx = i;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pos = widget.position.value;
      final idx = _indexFor(pos);
      if (idx != _activeIndex) {
        _activeIndex = idx;
        if (idx >= 0 && _controller.hasClients) {
          final target = idx * _lineHeight - _viewportCenter();
          _controller.animateTo(
            target.clamp(0.0, _controller.position.maxScrollExtent),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      }
      return ListView.builder(
        controller: _controller,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.3,
          horizontal: 24,
        ),
        itemCount: _lines.length,
        itemBuilder: (context, i) {
          final active = i == _activeIndex;
          return InkWell(
            onTap: () => widget.onTapSeek(_lines[i].$1),
            child: SizedBox(
              height: _lineHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _lines[i].$2.isEmpty ? '♪' : _lines[i].$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: active
                      ? widget.highlightStyle
                      : widget.textStyle.copyWith(
                          color: widget.textStyle.color?.withValues(alpha: 0.55),
                        ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  static const double _lineHeight = 40;

  double _viewportCenter() {
    final vp = _controller.position.viewportDimension;
    return vp / 2 - _lineHeight / 2;
  }
}
