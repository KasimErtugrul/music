import 'package:get/get.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/stats_repository.dart';
import 'package:resonance/presentation/controllers/home_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(
      () => LibraryController(Get.find<LibraryRepository>()),
      fenix: true,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<StatsRepository>(),
        Get.find<FavoriteRepository>(),
        Get.find<HistoryRepository>(),
        Get.find<LibraryRepository>(),
      ),
      fenix: true,
    );
  }
}