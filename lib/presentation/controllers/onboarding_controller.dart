import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gün 18: 5 sayfalık tanıtım (onboarding) akışı.
///
/// Sorumluluklar:
/// - Sayfa gezinmesi (PageController + [currentPage]); yalnızca son sayfada
///   «Başlayalım» akışı bitirir.
/// - «İlk açılış» bayrağı: `onboarding.completed` (SharedPreferences).
///   Splash, [shouldShow] doğruysa [start] ile akışı açar; bayrak bir kez
///   yazılır ve bir daha asla sıfırlanmaz (yeniden gösterim yalnız
///   uygulama verilerinin silinmesiyle olur — Kasa PIN'i ile aynı sözleşme).
/// - İzin köprüsü: durumun TEK kaynağı kalıcı [PermissionController]'dır
///   (InitialBinding). Onboarding kendi izin durumu TUTMAZ; böylece
///   ayarlardan dönüldüğünde (didChangeAppLifecycleState → refresh)
///   kartlar otomatik tazelenir ve iki ekran arasında çelişki doğmaz.
///
/// Akış sonu yönlendirme: medya izni verildiyse `/home`, verilmediyse
/// mevcut `/permission` kapısı — kapı, kalıcı ret hâlinde ayar bağlantısı
/// sunmaya devam eder; böylece izin hiçbir yoldan atlanamaz.
class OnboardingController extends GetxController {
  OnboardingController({
    required this._prefs,
    this._permission,
    void Function(String route)? navigate,
    PageController? pageController,
  })  : _navigate = navigate ?? ((route) => Get.offAllNamed<void>(route)),
        _ownsPageController = pageController == null,
        pageController = pageController ?? PageController();

  /// Kasa ile aynı ad alanı sözleşmesi: `alan.anlam` (bkz. vault.pin.*).
  static const String _kCompleted = 'onboarding.completed';

  /// Akış tam 5 sayfadır; UI ve testler bu sayıya bağlıdır.
  static const int totalPages = 5;

  static const Duration _pageDuration = Duration(milliseconds: 350);

  final SharedPreferences _prefs;
  final PermissionController? _permission;
  final void Function(String route) _navigate;
  final bool _ownsPageController;

  /// Testlerin kendi PageController'ını verebilmesi için public.
  final PageController pageController;

  PermissionController get permission =>
      _permission ?? Get.find<PermissionController>();

  final RxInt currentPage = 0.obs;
  final RxBool completed = false.obs;

  /// Splash'ın yönlendirme kararı için tek giriş noktası.
  bool get shouldShow => !(_prefs.getBool(_kCompleted) ?? false);

  bool get isLast => currentPage.value == totalPages - 1;

  bool get isMediaGranted => permission.media.value.isGranted;
  bool get isNotificationGranted => permission.notification.value.isGranted;

  /// Android < 13'te bildirim izni çalışma zamanında sorulmaz; adım
  /// bilgilendirici durumda çizilir (aynı 5 sayfa tüm cihazlarda korunur).
  bool get notificationRequired => permission.notificationRequired.value;

  void start() {
    if (!shouldShow) return;
    _navigate(AppRoutes.onboarding);
  }

  void onPageChanged(int page) => currentPage.value = page;

  Future<void> next() async {
    if (isLast) {
      await complete();
      return;
    }
    await pageController.nextPage(
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> previous() async {
    if (currentPage.value == 0) return;
    await pageController.previousPage(
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  /// «Atla» da akışı BİTİRİR: bayrak yazılır, izin verilmediyse mevcut
  /// izin kapısı devralır. Böylece «atla» bir geri dönüş tuzağına dönüşmez.
  Future<void> skip() => complete();

  Future<void> complete() async {
    if (completed.value) return;
    completed.value = true;
    try {
      await _prefs.setBool(_kCompleted, true);
    } on Exception {
      // Kalıcı depoya yazılamadı: akış yine biter; splash bir sonraki
      // açılışta bayrağı yeniden görür ve onboarding'i tekrar gösterir.
    }
    _navigate(isMediaGranted ? AppRoutes.home : AppRoutes.permission);
  }

  @override
  void onClose() {
    if (_ownsPageController) pageController.dispose();
    super.onClose();
  }
}
