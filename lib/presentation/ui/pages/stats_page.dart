import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/stats_controller.dart';

class StatsPage extends GetView<StatsController> {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        final stats = controller.stats.value;
        if (stats == null || stats.totalPlays == 0) {
          return Center(child: Text(l10n.noStatsYet));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _StatCard(
                  title: l10n.totalPlays,
                  value: '${stats.totalPlays}',
                  icon: Icons.play_circle_outline,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: l10n.uniqueSongsPlayed,
                  value: '${stats.uniqueSongsPlayed}',
                  icon: Icons.library_music,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(l10n.topArtists, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ...stats.topArtists.entries.map((e) => ListTile(
              title: Text(e.key),
              trailing: Text(l10n.playCount(e.value)),
            )),
            const SizedBox(height: 32),
            Text(l10n.topGenres, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ...stats.topGenres.entries.map((e) => ListTile(
              title: Text(e.key),
              trailing: Text(l10n.playCount(e.value)),
            )),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}