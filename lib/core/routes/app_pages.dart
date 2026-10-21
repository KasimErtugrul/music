import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/presentation/bindings/home_binding.dart';
import 'package:resonance/presentation/ui/pages/album_detail_page.dart';
import 'package:resonance/presentation/ui/pages/artist_detail_page.dart';
import 'package:resonance/presentation/ui/pages/genre_detail_page.dart';
import 'package:resonance/presentation/ui/pages/home_page.dart';
import 'package:resonance/presentation/ui/pages/permission_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';
import 'package:resonance/presentation/ui/pages/splash_page.dart';
import 'package:resonance/presentation/ui/pages/queue_page.dart';

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
    // Tek başına açıldığında da LibraryController gerektiği için
    // HomeBinding (LibraryController sağlıyor) burada da bağlanıyor.
    // GetX aynı bağımlılığı iki rotada da kullanabilir; lazyPut bunu yönetir.
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
    // import 'package:resonance/presentation/ui/pages/queue_page.dart';  (en üste ekle)
    GetPage<dynamic>(
      name: AppRoutes.queue,
      page: () => const QueuePage(),
    ),
  ];
}