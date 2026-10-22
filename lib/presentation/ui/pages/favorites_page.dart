import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/song_tile.dart';

class FavoritesPage extends GetView<FavoriteController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final libRepo = Get.find<LibraryRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favorites)),
      body: Obx(() {
        if (controller.favoriteIds.isEmpty) {
          return EmptyState(icon: Icons.favorite_border, title: l10n.favoritesEmpty);
        }
        
        return FutureBuilder(
          future: libRepo.songs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final songs = snapshot.data!.where((s) => controller.isFavorite(s.id)).toList();
            if (songs.isEmpty) return EmptyState(icon: Icons.favorite_border, title: l10n.favoritesEmpty);

            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, i) => SongTile(song: songs[i]),
            );
          },
        );
      }),
    );
  }
}