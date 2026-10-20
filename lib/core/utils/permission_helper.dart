import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Eklentiden bağımsız, uygulamanın kullandığı izin durumu.
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied;

  bool get isGranted => this == AppPermissionStatus.granted;

  static AppPermissionStatus fromPlugin(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    return AppPermissionStatus.denied;
  }
}

/// Medya ve bildirim izinleri. Android sürümüne göre doğru izni seçer:
/// API 33+ için `READ_MEDIA_AUDIO` (`Permission.audio`), API 32 ve altı için
/// `READ_EXTERNAL_STORAGE` (`Permission.storage`).
class PermissionHelper {
  PermissionHelper({Future<int> Function()? sdkIntLoader})
      : _sdkIntLoader = sdkIntLoader ?? _loadSdkInt;

  static const int _android13 = 33;

  final Future<int> Function() _sdkIntLoader;
  int? _sdkInt;

  static Future<int> _loadSdkInt() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<int> androidSdkInt() async => _sdkInt ??= await _sdkIntLoader();

  Future<Permission> mediaPermission() async =>
      await androidSdkInt() >= _android13
          ? Permission.audio
          : Permission.storage;

  Future<AppPermissionStatus> mediaStatus() async {
    final permission = await mediaPermission();
    return AppPermissionStatus.fromPlugin(await permission.status);
  }

  Future<AppPermissionStatus> requestMedia() async {
    final permission = await mediaPermission();
    return AppPermissionStatus.fromPlugin(await permission.request());
  }

  /// `POST_NOTIFICATIONS` çalışma zamanı izni yalnızca Android 13+ için vardır.
  Future<bool> notificationPermissionRequired() async =>
      await androidSdkInt() >= _android13;

  Future<AppPermissionStatus> notificationStatus() async {
    if (!await notificationPermissionRequired()) {
      return AppPermissionStatus.granted;
    }
    return AppPermissionStatus.fromPlugin(await Permission.notification.status);
  }

  Future<AppPermissionStatus> requestNotification() async {
    if (!await notificationPermissionRequired()) {
      return AppPermissionStatus.granted;
    }
    return AppPermissionStatus.fromPlugin(
      await Permission.notification.request(),
    );
  }

  Future<bool> openSettings() => openAppSettings();
}
