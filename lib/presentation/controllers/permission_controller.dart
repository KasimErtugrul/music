import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/utils/permission_helper.dart';

/// Medya (zorunlu) ve bildirim (isteğe bağlı) izin akışı.
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

  final RxBool mediaRequested = false.obs;
  final RxBool notificationRequired = false.obs;
  final RxBool busy = false.obs;

  bool get showNotificationCard =>
      notificationRequired.value && !notification.value.isGranted;

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
      // Durum okunamadı: önceki değerler korunur.
    }
  }

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
    _leaveIfDone();
  }

  Future<void> openSettings() async {
    await _helper.openSettings();
  }

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