import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/duration_extensions.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/mini_player.dart';
import 'package:resonance/presentation/ui/widgets/song_options_sheet.dart';

/// Çalma kuyruğu — M3 tasarım güncellemesi:
/// - Üstte "şu an çalan" vurgulu kart (EQ animasyonu + ÇALIYOR çipi +
///   oynat/duraklat düğmesi)
/// - "Sıradakiler" bölümü: sürükleme tutamacıyla yeniden sıralama
///   (ReorderableListView) + sağa kaydırarak kuyruktan çıkarma
///   (Dismissible) + parça seçenekleri + karıştır düğmesi
/// - Alt tarafta mini oynatıcı (tasarımdaki yüzen kart)
///
/// Tasarımdaki iki ayrı "Sonra Çalınacaklar / Sıradakiler" bölümü, veri
/// modelinde "play next" kuyruğu ayrı tutulmadığı için tek bir gerçek
/// listeye (mevcut indeksten sonraki parçalar) indirgendi; sahte bölüm
/// eklenmedi.
/// Not: `controller` (PlayerController) GetView getter'ı üzerinden gelir;
/// bu sınıf daha önce StatelessWidget olarak bildirilmişti ve `controller`
/// tanımsız kaldığı için dosya derlenmiyordu (kuyruk sayfası bu yüzden
/// hiçbir yerden açılamıyordu).
class QueuePage extends GetView<PlayerController> {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.queueTitle)),
      bottomNavigationBar: const MiniPlayer(),
      body: Obx(() {
        final queue = controller.songQueue;
        if (queue.isEmpty) {
          return EmptyState(
            icon: Icons.queue_music,
            title: l10n.queueEmpty,
          );
        }

        final curIdx = queue
            .indexWhere((s) => s.uri == controller.currentItem.value?.id);
        final current = curIdx >= 0 ? queue[curIdx] : null;
        final upNextOffset = curIdx >= 0 ? curIdx + 1 : 0;
        final upNext = queue.sublist(upNextOffset);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QueueHeader(count: queue.length),
            if (current != null) ...[
              const SizedBox(height: 2),
              _CurrentTrackCard(song: current),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: upNext.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.queueEmpty,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UpNextHeader(count: upNext.length),
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: upNext.length,
                            onReorder: (oldIndex, newIndex) =>
                                controller.reorderQueue(
                              upNextOffset + oldIndex,
                              upNextOffset + newIndex,
                            ),
                            itemBuilder: (context, i) {
                              final song = upNext[i];
                              final queueIndex = upNextOffset + i;
                              return _QueueItem(
                                key: ValueKey('queue-$queueIndex-${song.id}'),
                                song: song,
                                queueIndex: queueIndex,
                                listIndex: i,
                                onRemove: () =>
                                    controller.removeFromQueue(queueIndex),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// ========== ÜST BİLGİ (başlık + rozet + özet + temizle) ==========

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    // Kuyruk toplamı: parent Obx songQueue değişince burayı da yeniden
    // çizer (okuma Obx kapsamındadır).
    final totalMs = player.songQueue.fold<int>(
      0,
      (sum, s) => sum + s.durationMs,
    );
    final durText = _compactDuration(l10n, totalMs);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.queueTitle,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.queueLocalChip,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Gerçek özet: kuyruktaki parça sayısı + toplam süre.
                Text(
                  l10n.queueSummary(count, durText),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Temizle: hap biçimli tonal düğme (tasarımdaki pill).
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: cs.surfaceContainerLow,
              child: InkWell(
                onTap: () => _confirmClear(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 16, color: cs.primary),
                      const SizedBox(width: 5),
                      Text(
                        l10n.clearQueue,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compactDuration(AppLocalizations l10n, int totalMs) {
    final d = Duration(milliseconds: totalMs);
    if (d.inHours > 0) {
      return '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}';
    }
    return l10n.minutesShort(d.inMinutes);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearQueue),
        content: Text(l10n.clearQueueConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Get.find<PlayerController>().clearQueue();
    }
  }
}

// ========== ŞU AN ÇALAN KARTI ==========

class _CurrentTrackCard extends StatelessWidget {
  const _CurrentTrackCard({required this.song});
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Kapak + canlı EQ katmanı; dokununca tam oynatıcıyı açar.
            GestureDetector(
              onTap: () => Get.toNamed<void>(AppRoutes.player),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Obx(() {
                  final playing = player.isPlaying.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ArtworkImage(
                        songId: song.id,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _EqBars(isPlaying: playing),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ÇALIYOR çipi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.onPrimaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.nowPlayingBadge.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    song.artist ?? l10n.unknownArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => Text(
                player.duration.value.clock,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 44,
              height: 44,
              child: FilledButton(
                onPressed: player.togglePlayPause,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                child: Obx(
                  () => Icon(
                    player.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== SIRADAKILER BAŞLIĞI ==========

class _UpNextHeader extends StatelessWidget {
  const _UpNextHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final player = Get.find<PlayerController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      child: Row(
        children: [
          Icon(Icons.playlist_play, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.queueUpNextTitle} ($count)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Obx(() {
            final on = player.shuffleEnabled.value;
            return IconButton(
              tooltip: l10n.shuffleAll,
              icon: Icon(
                Icons.shuffle,
                size: 18,
                color: on ? cs.primary : cs.onSurfaceVariant,
              ),
              onPressed: player.toggleShuffle,
            );
          }),
        ],
      ),
    );
  }
}

// ========== KUYRUK ÖĞESİ (sürükle + kaydır + seçenekler) ==========

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    super.key,
    required this.song,
    required this.queueIndex,
    required this.listIndex,
    required this.onRemove,
  });

  final SongModel song;

  /// Tam kuyruktaki konum (kaldırma/sıralama çağrıları için).
  final int queueIndex;

  /// "Sıradakiler" bölümündeki konum (ReorderableDragStartListener için).
  final int listIndex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    return Dismissible(
      // Anahtar kuyruk pozisyonunu içerir: aynı şarkı iki kez olsa bile
      // ReorderableListView/Dismissible çakışmaz.
      key: ValueKey('dismiss-$queueIndex-${song.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove, color: cs.onErrorContainer, size: 20),
            const SizedBox(width: 6),
            Text(
              l10n.queueRemoveAction,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => player.playSong(
            song,
            queue: player.songQueue.toList(),
          ),
          onLongPress: () => SongOptionsSheet.show(context, song),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // Sürükleme tutamacı (tasarımdaki drag_indicator)
                ReorderableDragStartListener(
                  index: listIndex,
                  child: SizedBox(
                    width: 30,
                    height: 40,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: cs.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ArtworkImage(
                    songId: song.id,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        song.artist ?? l10n.unknownArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  song.duration.clock,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  tooltip: l10n.songInfo,
                  icon: Icon(Icons.more_vert,
                      size: 20, color: cs.onSurfaceVariant),
                  onPressed: () => SongOptionsSheet.show(context, song),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== EQ BARI ANİMASYONU ==========

class _EqBars extends StatefulWidget {
  const _EqBars({required this.isPlaying});
  final bool isPlaying;

  @override
  State<_EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<_EqBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _EqBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(color, 0.3, 0.7),
            _bar(color, 0.7, 1.0),
            _bar(color, 0.45, 0.85),
            _bar(color, 0.6, 0.95),
          ],
        );
      },
    );
  }

  Widget _bar(Color color, double min, double max) {
    final v = widget.isPlaying ? _controller.value : min;
    final height = 8 + 18 * (min + (max - min) * v);
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
