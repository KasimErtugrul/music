import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:resonance/core/utils/permission_helper.dart';

void main() {
  group('AppPermissionStatus.fromPlugin', () {
    test('granted ve limited -> granted', () {
      expect(
        AppPermissionStatus.fromPlugin(PermissionStatus.granted),
        AppPermissionStatus.granted,
      );
      expect(
        AppPermissionStatus.fromPlugin(PermissionStatus.limited),
        AppPermissionStatus.granted,
      );
    });

    test('permanentlyDenied -> permanentlyDenied', () {
      expect(
        AppPermissionStatus.fromPlugin(PermissionStatus.permanentlyDenied),
        AppPermissionStatus.permanentlyDenied,
      );
    });

    test('denied ve restricted -> denied', () {
      expect(
        AppPermissionStatus.fromPlugin(PermissionStatus.denied),
        AppPermissionStatus.denied,
      );
      expect(
        AppPermissionStatus.fromPlugin(PermissionStatus.restricted),
        AppPermissionStatus.denied,
      );
    });
  });

  group('PermissionHelper Android sürüm ayrımı', () {
    test('API 33 ve üstü: audio izni, bildirim izni gerekli', () async {
      final helper = PermissionHelper(sdkIntLoader: () async => 33);
      expect(await helper.mediaPermission(), Permission.audio);
      expect(await helper.notificationPermissionRequired(), isTrue);
    });

    test('API 32 ve altı: storage izni, bildirim izni gerekmez', () async {
      final helper = PermissionHelper(sdkIntLoader: () async => 32);
      expect(await helper.mediaPermission(), Permission.storage);
      expect(await helper.notificationPermissionRequired(), isFalse);
      expect(
        await helper.notificationStatus(),
        AppPermissionStatus.granted,
      );
    });

    test('sdk sürümü bir kez okunur', () async {
      var calls = 0;
      final helper = PermissionHelper(
        sdkIntLoader: () async {
          calls++;
          return 34;
        },
      );
      await helper.mediaPermission();
      await helper.notificationPermissionRequired();
      expect(calls, 1);
    });
  });
}
