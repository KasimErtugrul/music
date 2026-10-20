import 'package:get/get.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';

/// Uygulama genelinde kalıcı bağımlılıklar burada kaydedilir.
/// `PlayerController` (permanent) Gün 8'de eklenecek.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionHelper>(PermissionHelper(), permanent: true);
    // Splash ve izin sayfası aynı örneği kullanır; fenix: rota değişiminde
    // silinirse yeniden oluşturulur.
    Get.lazyPut<PermissionController>(
      () => PermissionController(Get.find<PermissionHelper>()),
      fenix: true,
    );
  }
}
