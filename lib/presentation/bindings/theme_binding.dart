import 'package:get/get.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class ThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ThemeController>(() => ThemeController(), fenix: true);
  }
}