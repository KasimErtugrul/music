import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetDatasource {
  static const _qualifiedAndroidName =
      'com.example.resonance.widget.MusicWidgetProvider';

  Future<void> saveData({
    required String title,
    required String artist,
    required bool isPlaying,
    required bool isTransparent,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('song_title', title);
      await HomeWidget.saveWidgetData<String>('artist_name', artist);
      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);
      await HomeWidget.saveWidgetData<bool>('widget_transparent', isTransparent);
    } catch (e, st) {
      debugPrint('HomeWidget.saveData hatası: $e\n$st');
    }
  }

  /// Kapak resmini uygulamanın özel (private) klasörüne yazar
  /// ve yolu `SharedPreferences`'a kaydeder. Widget süreci
  /// (launcher) bu dosyayı doğrudan okumaz; `onUpdate` içinde
  /// uygulama süreci okur ve RemoteViews'a `Bitmap` olarak koyar.
  Future<void> saveArtwork(Uint8List? bytes) async {
    try {
      if (bytes == null || bytes.isEmpty) {
        // Kapaksuz şarkıda önceki şarkının kapağı kalmasın.
        await HomeWidget.saveWidgetData<String>('artwork_path', '');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/widget_artwork.jpg');
      await file.writeAsBytes(bytes, flush: true);
      await HomeWidget.saveWidgetData<String>('artwork_path', file.path);
    } catch (e, st) {
      debugPrint('HomeWidget.saveArtwork hatası: $e\n$st');
    }
  }

  Future<void> updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (e, st) {
      debugPrint('HomeWidget.updateWidget hatası: $e\n$st');
    }
  }
}