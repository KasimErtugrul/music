import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:resonance/core/errors/app_exception.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';

/// GEÇİCİ (Gün 3): MediaStore kanalından gelen ham listeyi gösterir.
///
/// MİMARİ SAPMA (bilinçli, geçici): UI datasource'u doğrudan çağırır. Gün 4'te
/// `library_repository` + `library_controller` gelir, Gün 5'te bu sayfa gerçek
/// Şarkılar sekmesiyle değişir.
class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final DeviceMediaDataSource _source = MediaStoreChannelDataSource();

  List<SongModel>? _songs;
  bool _loading = false;
  bool _failed = false;
  int _elapsedMs = 0;

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final watch = Stopwatch()..start();
    try {
      final songs = await _source.querySongs();
      watch.stop();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _elapsedMs = watch.elapsedMilliseconds;
        _loading = false;
      });
    } on AppException {
      if (!mounted) return;
      setState(() {
        _songs = null;
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final songs = _songs;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spikeTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                onPressed: _loading ? null : _scan,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.spikeScanButton),
              ),
            ),
            if (songs != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.spikeStats(songs.length, _elapsedMs),
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      l10n.spikeMissingStats(
                        songs.where((s) => s.artist == null).length,
                        songs.where((s) => s.genre == null).length,
                      ),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context, l10n, songs)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<SongModel>? songs,
  ) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return _Message(text: l10n.spikeLoadError);
    if (songs == null) return _Message(text: l10n.spikeNotScanned);
    if (songs.isEmpty) return _Message(text: l10n.spikeEmpty);

    return ListView.builder(
      itemCount: songs.length,
      itemExtent: 64,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          key: ValueKey<int>(song.id),
          leading: _SpikeArtwork(source: _source, songId: song.id),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${song.artist ?? l10n.unknownArtist} • '
            '${song.album ?? l10n.unknownAlbum}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(song.duration.clock),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}

/// Kapak denemesi: görünür satır başına bir sorgu (önbellek yok; Gün 5'te
/// `artwork_image` önbellekli yazılır).
class _SpikeArtwork extends StatefulWidget {
  const _SpikeArtwork({required this.source, required this.songId});

  final DeviceMediaDataSource source;
  final int songId;

  @override
  State<_SpikeArtwork> createState() => _SpikeArtworkState();
}

class _SpikeArtworkState extends State<_SpikeArtwork> {
  late Future<Uint8List?> _future =
      widget.source.queryArtwork(widget.songId, size: 96);

  @override
  void didUpdateWidget(covariant _SpikeArtwork old) {
    super.didUpdateWidget(old);
    if (old.songId != widget.songId || old.source != widget.source) {
      _future = widget.source.queryArtwork(widget.songId, size: 96);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null) {
              return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
            }
            return ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
            );
          },
        ),
      ),
    );
  }
}
