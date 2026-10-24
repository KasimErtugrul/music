import 'package:flutter/services.dart';

class ExternalIntentDatasource {
  static const _channel = MethodChannel('com.example.resonance/media_store');
  
  Future<String?> getInitialIntent() async {
    return await _channel.invokeMethod<String>('getExternalUri');
  }

  // Kotlin'den Flutter'a yeni bir intent geldiğinde dinleyici
  void listenToIntents(void Function(String uri) onUriReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onExternalIntent') {
        final uri = call.arguments as String?;
        if (uri != null) onUriReceived(uri);
      }
    });
  }
}