import 'package:resonance/core/utils/permission_helper.dart';

/// Gün 18 testleri: eklentiye dokunmayan sahte PermissionHelper.
///
/// PermissionHelper somut sınıftır; tüm yöntemler geçersiz kılınabilir.
/// Böylece testler hem device_info_plus hem permission_handler kanallarına
/// hiç gitmeden izin durumlarını senaryolaştırır.
class FakePermissionHelper extends PermissionHelper {
  FakePermissionHelper({
    this.media = AppPermissionStatus.denied,
    this.notification = AppPermissionStatus.denied,
    this._notificationRequired = true,
  })  : super(sdkIntLoader: () async => 34);

  AppPermissionStatus media;
  AppPermissionStatus notification;
  final bool _notificationRequired;

  int requestMediaCalls = 0;
  int requestNotificationCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<int> androidSdkInt() async => 34;

  @override
  Future<bool> notificationPermissionRequired() async =>
      _notificationRequired;

  @override
  Future<AppPermissionStatus> mediaStatus() async => media;

  @override
  Future<AppPermissionStatus> requestMedia() async {
    requestMediaCalls++;
    return media;
  }

  @override
  Future<AppPermissionStatus> notificationStatus() async => notification;

  @override
  Future<AppPermissionStatus> requestNotification() async {
    requestNotificationCalls++;
    return notification;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}
