import 'package:get/get.dart';
import 'package:resonance/data/datasources/local/daos/playlist_dao.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/presentation/controllers/playlist_controller.dart';

class PlaylistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaylistRepository>(
      () => PlaylistRepositoryImpl(
        Get.find<PlaylistDao>(),
        Get.find<LibraryRepository>(),
      ),
      fenix: true,
    );
    Get.lazyPut<PlaylistController>(
      () => PlaylistController(Get.find<PlaylistRepository>()),
      fenix: true,
    );
  }
}