import 'package:resonance/data/datasources/waveform_datasource.dart';
import 'package:resonance/data/models/waveform_model.dart';

abstract class WaveformRepository {
  Future<WaveformModel?> getWaveform(String songPath);
}

class WaveformRepositoryImpl implements WaveformRepository {
  final WaveformDatasource _datasource;
  WaveformRepositoryImpl(this._datasource);

  @override
  Future<WaveformModel?> getWaveform(String songPath) async {
    // Önce cache kontrolü
    final cached = await _datasource.getCachedWaveform(songPath);
    if (cached != null) return cached;

    // Cache yoksa çıkar
    return await _datasource.extractAndCache(songPath);
  }
}