import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ExternalIntentDatasource {
  static const _channel = MethodChannel('com.example.resonance/media_store');

  /// Kanalın callback tipi: String parametre alan fonksiyon.
  /// (VoidCallback = void Function() olduğu için kullanılamaz.)
  void Function(String)? _callback;

  ExternalIntentDatasource() {
    // Kanal dinleyicisini bir kez kur. Aynı kanal başka bir yerde
    // (ör. MediaStore datasource) da kullanılıyor olabilir, ama
    // `setMethodCallHandler` her çağrıldığında önceki handler'ı
    // değiştirir. Bu yüzden tek bir yerde kurmamız önemli.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onExternalIntent') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) {
          _callback?.call(uri);
        }
      }
    });
  }

  Future<String?> getInitialIntent() async {
    try {
      return await _channel.invokeMethod<String>('getExternalUri');
    } catch (e, st) {
      debugPrint('getInitialIntent hatası: $e\n$st');
      return null;
    }
  }

  void listenToIntents(void Function(String uri) onUriReceived) {
    _callback = onUriReceived;
  }
}