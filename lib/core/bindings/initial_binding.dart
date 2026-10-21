import 'package:get/get.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/datasources/device_media_datasource.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionHelper>(PermissionHelper(), permanent: true);
    Get.lazyPut<PermissionController>(
      () => PermissionController(Get.find<PermissionHelper>()),
      fenix: true,
    );
    Get.lazyPut<DeviceMediaDataSource>(
      () => MediaStoreChannelDataSource(),
      fenix: true,
    );
    Get.lazyPut<LibraryRepository>(
      () => LibraryRepositoryImpl(Get.find<DeviceMediaDataSource>()),
      fenix: true,
    );

    // Gün 8: AudioHandler `main()`'de kaydedilir (ResonanceApp çalışmadan önce).
    Get.put<PlayerRepository>(
      PlayerRepositoryImpl(Get.find<ResonanceAudioHandler>()),
      permanent: true,
    );
    Get.put<PlayerController>(
      PlayerController(Get.find<PlayerRepository>()),
      permanent: true,
    );
  }
}