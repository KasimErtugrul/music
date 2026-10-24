import 'dart:convert';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resonance/data/models/waveform_model.dart';

class WaveformDatasource {
  Future<Directory> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/waveforms');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String _getCacheFileName(String path) {
    return 'wave_${path.hashCode}.json';
  }

  Future<WaveformModel?> getCachedWaveform(String songPath) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_getCacheFileName(songPath)}');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final list = (json['data'] as List).cast<num>().map((e) => e.toDouble()).toList();

      return WaveformModel(
        songPath: songPath,
        waveformData: list,
        createdAt: DateTime.parse(json['date'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<WaveformModel?> extractAndCache(String songPath) async {
    WaveformExtractionController? controller;
    try {
      if (!await File(songPath).exists()) return null;

      controller = WaveformExtractionController();
      final rawData = await controller.extractWaveformData(
        path: songPath,
        noOfSamples: 200,
      );

      if (rawData.isEmpty) return null;

      final data = rawData.map((e) => e.toDouble()).toList();

      final model = WaveformModel(
        songPath: songPath,
        waveformData: data,
        createdAt: DateTime.now(),
      );

      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_getCacheFileName(songPath)}');
      await file.writeAsString(jsonEncode({
        'data': data,
        'date': model.createdAt.toIso8601String(),
      }));

      return model;
    } catch (e) {
      return null;
    } 
  }
}