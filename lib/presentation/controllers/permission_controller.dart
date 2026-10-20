import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';

/// Medya (zorunlu) ve bildirim (isteğe bağlı) izin akışı.
///
/// Bildirim izni reddedilse bile çalma etkilenmez; yalnızca medya izni
/// uygulamanın ana ekranına geçişi belirler.
class PermissionController extends GetxController with WidgetsBindingObserver {
  PermissionController(
    this._helper, {
    void Function(String route)? navigate,
    String Function()? currentRoute,
  })  : _navigate = navigate ?? ((route) => Get.offAllNamed<void>(route)),
        _currentRoute = currentRoute ?? (() => Get.currentRoute);

  final PermissionHelper _helper;
  final void Function(String route) _navigate;
  final String Function() _currentRoute;

  final Rx<AppPermissionStatus> media = AppPermissionStatus.denied.obs;
  final Rx<AppPermissionStatus> notification = AppPermissionStatus.denied.obs;

  /// Bu oturumda medya izni en az bir kez istendi mi (reddedildi mesajı için).
  final RxBool mediaRequested = false.obs;
  final RxBool notificationRequired = false.obs;

  /// Bildirim kartı kapatıldı veya bir kez soruldu (yalnızca bellekte tutulur).
  final RxBool notificationDismissed = false.obs;
  final RxBool busy = false.obs;

  bool get showNotificationCard =>
      notificationRequired.value &&
      !notification.value.isGranted &&
      !notificationDismissed.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }

  Future<void> _onResumed() async {
    await refresh();
    _leaveIfDone();
  }

  /// Splash: durumu oku, ana sayfaya veya izin sayfasına git.
  Future<void> checkAndRoute() async {
    await refresh();
    _navigate(media.value.isGranted ? AppRoutes.home : AppRoutes.permission);
  }

  Future<void> refresh() async {
    try {
      final freshMedia = await _helper.mediaStatus();
      final required = await _helper.notificationPermissionRequired();
      final freshNotification = await _helper.notificationStatus();
      media.value = _merge(media.value, freshMedia);
      notificationRequired.value = required;
      notification.value = _merge(notification.value, freshNotification);
    } on Exception {
      // Durum okunamadı: önceki değerler korunur. Hata günlüğü Gün 31'de.
    }
  }

  /// Eklenti, "bir daha sorma" durumunu `request()` sonucunda bildirir; sonraki
  /// `status` okuması yalnızca `denied` dönebilir. Kalıcı reddi yanlışlıkla
  /// geri almamak için `denied` okuması `permanentlyDenied`'ı ezmez.
  /// DOĞRULANMADI: gerçek cihaz davranışı.
  AppPermissionStatus _merge(
    AppPermissionStatus current,
    AppPermissionStatus fresh,
  ) {
    if (fresh == AppPermissionStatus.denied &&
        current == AppPermissionStatus.permanentlyDenied) {
      return current;
    }
    return fresh;
  }

  Future<void> requestMedia() async {
    if (busy.value) return;
    busy.value = true;
    try {
      media.value = await _helper.requestMedia();
      mediaRequested.value = true;
    } on Exception {
      mediaRequested.value = true;
    } finally {
      busy.value = false;
    }
    _leaveIfDone();
  }

  Future<void> requestNotification() async {
    if (busy.value) return;
    busy.value = true;
    try {
      notification.value = await _helper.requestNotification();
    } on Exception {
      // Bildirim izni isteğe bağlıdır; hata çalmayı etkilemez.
    } finally {
      busy.value = false;
    }
    // Bir kez soruldu: kart gizlenir. Tekrar deneme İzinler ayarından (Gün 21).
    notificationDismissed.value = true;
    _leaveIfDone();
  }

  void dismissNotification() {
    notificationDismissed.value = true;
    _leaveIfDone();
  }

  Future<void> openSettings() async {
    await _helper.openSettings();
  }

  /// "Devam et": medya izni verilmiş ve bildirim kartı hâlâ bekliyorsa.
  void continueToApp() {
    if (media.value.isGranted) _navigate(AppRoutes.home);
  }

  void _leaveIfDone() {
    if (media.value.isGranted &&
        !showNotificationCard &&
        _currentRoute() == AppRoutes.permission) {
      _navigate(AppRoutes.home);
    }
  }
}
