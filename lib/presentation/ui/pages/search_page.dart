import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/search_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class SearchPage extends GetView<AppSearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: controller.onQueryChanged,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Obx(() {
        if (controller.query.value.trim().isEmpty) {
          return EmptyState(
            icon: Icons.search,
            title: l10n.noSearchYet,
          );
        }
        
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = controller.results.value;
        if (result == null || result.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: l10n.searchEmptyTitle,
            message: l10n.searchEmptyMessage,
          );
        }

        return ListView(
          children: [
            if (result.songs.isNotEmpty) ...<Widget>[
              _SectionHeader(title: l10n.libraryTabSongs),
              ...result.songs.map((s) => SongTile(
                song: s,
                queueContext: result.songs,
              )),
            ],
            if (result.albums.isNotEmpty) ...<Widget>[
              _SectionHeader(title: l10n.libraryTabAlbums),
              ...result.albums.map((a) => ListTile(
                leading: ArtworkImage(songId: a.artworkSongId, size: 48, borderRadius: BorderRadius.circular(4)),
                title: Text(a.title ?? l10n.unknownAlbum),
                subtitle: Text(a.artist ?? l10n.unknownArtist),
                onTap: () => Get.toNamed(AppRoutes.albumDetail, arguments: a),
              )),
            ],
            if (result.artists.isNotEmpty) ...<Widget>[
              _SectionHeader(title: l10n.libraryTabArtists),
              ...result.artists.map((a) => ListTile(
                leading: ArtworkImage(songId: a.artworkSongId, size: 48, borderRadius: BorderRadius.circular(24)),
                title: Text(a.name ?? l10n.unknownArtist),
                onTap: () => Get.toNamed(AppRoutes.artistDetail, arguments: a),
              )),
            ],
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}