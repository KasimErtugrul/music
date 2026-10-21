import 'package:get/get.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';

/// Home rotasıyla birlikte `LibraryController`'ı kaydeder.
/// `LibraryRepository` zaten `InitialBinding`'de kayıtlı olduğu varsayılır.
/// `fenix: true` — rota yeniden girildiğinde controller yeniden oluşur.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(
      () => LibraryController(Get.find<LibraryRepository>()),
      fenix: true,
    );
  }
}