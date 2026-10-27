import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/repositories/library_repository.dart';

/// Kapak görseli. `size` verilirse kare boyutta gösterir; `null` verilirse
/// mevcut alanı doldurur. Bayt düzeyinde LRU önbellek kullanır
/// (`id, requestSize` çifti anahtardır).
class ArtworkImage extends StatefulWidget {
  const ArtworkImage({
    super.key,
    required this.songId,
    this.size,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.music_note,
  });

  /// null ise placeholder doğrudan gösterilir.
  final int? songId;

  /// null → mevcut alanı doldur. Sayı → kare boyut.
  final double? size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;

  /// Görev 1.4: "Kapak önbelleğini temizle" düğmesinin gerçek temizliği için
  /// statik boşaltma noktası. Bayt LRU'su [_ArtworkImageState._cache] içinde
  /// yaşadığından temizlik ona delege edilir (aynı kütüphanede olduğundan
  /// private sınıfa erişim serbesttir).
  static void clearCache() => _ArtworkImageState.clearCache();

  @override
  State<ArtworkImage> createState() => _ArtworkImageState();
}

class _ArtworkImageState extends State<ArtworkImage> {
  static final Map<(int, int), Uint8List?> _cache = <(int, int), Uint8List?>{};
  static const int _maxCache = 200;

  /// Görev 1.4: Bayt LRU önbelleğini boşaltır. Widget'lar yeniden çizimde
  /// veriyi [LibraryRepository.artwork] üzerinden taze çeker. Dışarıdan
  /// çağrı [ArtworkImage.clearCache] üzerinden yapılır.
  static void clearCache() => _cache.clear();

  Uint8List? _data;
  bool _loading = true;
  bool _firstLoadScheduled = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_firstLoadScheduled) {
      _firstLoadScheduled = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant ArtworkImage old) {
    super.didUpdateWidget(old);
    if (old.songId != widget.songId || old.size != widget.size) {
      _data = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_generation;
    final id = widget.songId;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final basePx = widget.size ?? 200.0;
    final requestSize = (basePx * dpr).round().clamp(32, 1024);
    final key = (id, requestSize);

    if (_cache.containsKey(key)) {
      if (mounted && gen == _generation) {
        setState(() {
          _data = _cache[key];
          _loading = false;
        });
      }
      return;
    }

    try {
      final bytes = await Get.find<LibraryRepository>().artwork(
        id,
        size: requestSize,
      );
      if (!mounted || gen != _generation) return;
      if (_cache.length >= _maxCache) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = bytes;
      setState(() {
        _data = bytes;
        _loading = false;
      });
    } on Object {
      if (!mounted || gen != _generation) return;
      _cache[key] = null;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_loading || _data == null) {
      content = ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            widget.fallbackIcon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      );
    } else {
      content = Image.memory(
        _data!,
        fit: widget.fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    final sized = widget.size != null
        ? SizedBox(width: widget.size, height: widget.size, child: content)
        : SizedBox.expand(child: content);

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: sized,
    );
  }
}
