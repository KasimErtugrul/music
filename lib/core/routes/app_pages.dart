import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/presentation/bindings/home_binding.dart';
import 'package:resonance/presentation/ui/pages/album_detail_page.dart';
import 'package:resonance/presentation/ui/pages/artist_detail_page.dart';
import 'package:resonance/presentation/ui/pages/favorites_page.dart';
import 'package:resonance/presentation/ui/pages/genre_detail_page.dart';
import 'package:resonance/presentation/ui/pages/history_page.dart';
import 'package:resonance/presentation/ui/pages/home_page.dart';
import 'package:resonance/presentation/ui/pages/permission_page.dart';
import 'package:resonance/presentation/ui/pages/player/player_page.dart';
import 'package:resonance/presentation/ui/pages/playlist_detail_page.dart';
import 'package:resonance/presentation/ui/pages/playlists/smart_playlists_page.dart';
import 'package:resonance/presentation/ui/pages/queue_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';
import 'package:resonance/presentation/ui/pages/splash_page.dart';
import 'package:resonance/presentation/ui/pages/stats_page.dart';
abstract final class AppPages {
  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<dynamic>(
      name: AppRoutes.permission,
      page: () => const PermissionPage(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.songs,
      page: () => const SongsPage(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.albumDetail,
      page: () => const AlbumDetailPage(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.artistDetail,
      page: () => const ArtistDetailPage(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.genreDetail,
      page: () => const GenreDetailPage(),
    ),
    GetPage<dynamic>(name: AppRoutes.queue, page: () => const QueuePage()),
    GetPage<dynamic>(name: AppRoutes.player, page: () => const PlayerPage()),
    GetPage<dynamic>(
      name: AppRoutes.playlistDetail,
      page: () => const PlaylistDetailPage(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
    ),
    GetPage<dynamic>(name: AppRoutes.history, page: () => const HistoryPage()),
    GetPage(
      name: AppRoutes.smartPlaylists,
      page: () => const SmartPlaylistsPage(),
    ),
    GetPage(name: AppRoutes.stats, page: () => const StatsPage()),
  ];
}
