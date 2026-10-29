import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/play_stats_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/history_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

/// İstatistikler — M3 tasarım güncellemesi:
/// - Dönem seçici (Bu Hafta / Bu Ay / Tüm Zamanlar): gerçek tarih filtresiyle
///   istatistikleri yeniden hesaplar (StatsRepository.getStats(since:))
/// - Ana KPI kartı: toplam dinleme süresi (çalma olaylarının parça süreleri
///  yle yaklaşıklanır) + çalma sayısı rozeti
/// - Haftalık dağılım grafiği: gerçek gün bazlı çalma sayıları, zirve gün
///   vurgulu; altında zirve özeti
/// - En çok dinlenen sanatçılar (pay yüzdesiyle) ve şarkılar (çal + sayaç)
/// - Son Çalınanlar: son 24 saat, göreli zaman etiketleri + geçmişi temizle
/// - Yerel-gizlilik bandı: tüm veriler cihazda kalır
///
/// Tasarımdaki "Kayıpsız Format %" KPI'sı EKLENMEDİ: çalma geçmişinde
/// kodlama bilgisi yoktur, yüzde uydurulamaz.
class StatsPage extends GetView<StatsController> {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = controller.stats.value;
        if (stats == null || stats.totalPlays == 0) {
          return EmptyState(
            icon: Icons.query_stats_outlined,
            title: l10n.noStatsYet,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadStats,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _PeriodSelector(period: controller.period),
              const SizedBox(height: 12),
              _MainKpiCard(stats: stats),
              const SizedBox(height: 10),
              _SmallKpiRow(stats: stats),
              const SizedBox(height: 16),
              _WeeklyChartCard(counts: stats.weeklyCounts, totalPlays: stats.totalPlays),
              const SizedBox(height: 16),
              if (stats.topArtists.isNotEmpty) ...<Widget>[
                _TopArtistsCard(stats: stats),
                const SizedBox(height: 16),
              ],
              if (stats.topSongs.isNotEmpty) ...<Widget>[
                _TopTracksCard(stats: stats),
                const SizedBox(height: 16),
              ],
              const _RecentSection(),
              const SizedBox(height: 16),
              const _PrivacyBanner(),
            ],
          ),
        );
      }),
    );
  }
}

// ========== DÖNEM SEÇİCİ ==========

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period});
  final RxInt period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ctrl = Get.find<StatsController>();

    final labels = <String>[
      l10n.statsPeriodWeek,
      l10n.statsPeriodMonth,
      l10n.statsPeriodAll,
    ];

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...<Widget>[
              Expanded(
                child: Material(
                  color: period.value == i
                      ? cs.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => ctrl.setPeriod(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: period.value == i
                              ? cs.onSecondaryContainer
                              : cs.onSurfaceVariant,
                          fontWeight:
                              period.value == i ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== ANA KPI ==========

class _MainKpiCard extends StatelessWidget {
  const _MainKpiCard({required this.stats});
  final PlayStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final d = Duration(milliseconds: stats.totalListenMs);
    final listenText = d.inHours > 0
        ? '${l10n.hoursShort(d.inHours)} ${l10n.minutesShort(d.inMinutes.remainder(60))}'
        : l10n.minutesShort(d.inMinutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 15, color: cs.primary),
                    const SizedBox(width: 5),
                    Text(
                      l10n.statsTotalListen,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listenText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.playCount(stats.totalPlays),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.graphic_eq, size: 26, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

class _SmallKpiRow extends StatelessWidget {
  const _SmallKpiRow({required this.stats});
  final PlayStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _SmallKpiCard(
            icon: Icons.queue_music,
            label: l10n.uniqueSongsPlayed,
            value: '${stats.uniqueSongsPlayed}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallKpiCard(
            icon: Icons.play_circle_outline,
            label: l10n.totalPlays,
            value: '${stats.totalPlays}',
          ),
        ),
      ],
    );
  }
}

class _SmallKpiCard extends StatelessWidget {
  const _SmallKpiCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: cs.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== HAFTALIK GRAFİK ==========

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.counts, required this.totalPlays});
  final List<int> counts;
  final int totalPlays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final peak = counts
        .indexed
        .reduce((a, b) => b.$2 > a.$2 ? b : a);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.statsWeeklyChart,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.statsPeriodWeek,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 7; i++) ...<Widget>[
                  Expanded(child: _bar(context, i, counts[i], peak.$1)),
                  if (i < 6) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (peak.$2 > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.statsWeeklyPeak(
                        _dayName(context, peak.$1),
                        peak.$2,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int index, int value, int peakIndex) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPeak = index == peakIndex && value > 0;
    final max = peakIndex >= 0 && counts.isNotEmpty
        ? counts.reduce((a, b) => a > b ? a : b)
        : 1;
    final ratio = value <= 0 ? 0.0 : (value / (max > 0 ? max : 1)).clamp(0.06, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: isPeak ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _dayName(context, index),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isPeak ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _dayName(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    return switch (index) {
      0 => l10n.statsDayMon,
      1 => l10n.statsDayTue,
      2 => l10n.statsDayWed,
      3 => l10n.statsDayThu,
      4 => l10n.statsDayFri,
      5 => l10n.statsDaySat,
      _ => l10n.statsDaySun,
    };
  }
}

// ========== EN ÇOK DİNLENEN SANATÇILAR ==========

class _TopArtistsCard extends StatelessWidget {
  const _TopArtistsCard({required this.stats});
  final PlayStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = stats.topArtists.entries.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Icon(Icons.mic, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.topArtists,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: i == 0 ? cs.surfaceContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Icon(Icons.person, color: cs.primary),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: i == 0 ? cs.primary : cs.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: i == 0
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.playCount(entries[i].value),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.statsSharePct(
                        ((entries[i].value / stats.totalPlays) * 100).round()),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: i == 0 ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ========== EN ÇOK DİNLENEN ŞARKILAR ==========

class _TopTracksCard extends StatelessWidget {
  const _TopTracksCard({required this.stats});
  final PlayStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    final entries = stats.topSongs.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Icon(Icons.music_note, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.statsTopTracks,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: i == 0 ? cs.surfaceContainer : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: ArtworkImage(
                          songId: entries[i].song.id,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: i == 0 ? cs.primary : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: i == 0 ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: i == 0 ? cs.primary : cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entries[i].song.artist ?? l10n.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.playCount(entries[i].playCount),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: l10n.playInOrder,
                      icon: Icon(Icons.play_circle, size: 26, color: cs.primary),
                      onPressed: () =>
                          player.playSong(entries[i].song, queue: [
                        for (final e in entries) e.song,
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ========== SON ÇALINANLAR ==========

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  String _relative(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.statsRelNow;
    if (diff.inMinutes < 60) return l10n.statsRelMinutes(diff.inMinutes);
    return l10n.statsRelHours(diff.inHours);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
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
      await Get.find<HistoryController>().clearHistory();
      await Get.find<StatsController>().loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final player = Get.find<PlayerController>();

    return Obx(() {
      final items = Get.find<StatsController>().recent;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.statsRecent24h,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmClear(context),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    child: Text(l10n.clearHistory),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.historyEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            ...items.take(5).map((play) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: ArtworkImage(
                          songId: play.song.id,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              play.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              play.song.artist ?? l10n.unknownArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _relative(context, play.playedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          tooltip: l10n.playInOrder,
                          icon: Icon(Icons.play_arrow,
                              size: 22, color: cs.onSurfaceVariant),
                          onPressed: () =>
                              player.playSong(play.song, queue: [
                            for (final p in items) p.song,
                          ]),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      );
    });
  }
}

// ========== GİZLİLİK BANDI ==========

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsPrivacyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.statsPrivacyBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
