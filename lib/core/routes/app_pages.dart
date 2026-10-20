import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/presentation/ui/pages/home_page.dart';
import 'package:resonance/presentation/ui/pages/permission_page.dart';
import 'package:resonance/presentation/ui/pages/songs_page.dart';
import 'package:resonance/presentation/ui/pages/splash_page.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<dynamic>(
      name: AppRoutes.permission,
      page: () => const PermissionPage(),
    ),
    GetPage<dynamic>(name: AppRoutes.home, page: () => const HomePage()),
    GetPage<dynamic>(name: AppRoutes.songs, page: () => const SongsPage()),
  ];
}
