import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/equalizer_datasource.dart';
import 'package:resonance/data/models/equalizer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class EqualizerRepository {
  Future<AndroidEqualizerParameters> getParameters();
  Future<void> setBandGain(int index, double gain);
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<void> setLoudnessGain(double gain);
  Future<List<EqualizerPresetModel>> getPresets();
  Future<void> savePreset(String name, List<double> gains);
  Future<void> deletePreset(int id);
}

class EqualizerRepositoryImpl implements EqualizerRepository {
  final AudioEffectsDatasource _effects;
  final EqualizerDatasource _db;
  final SharedPreferences _prefs;

  static const _enabledKey = 'equalizer_enabled';

  EqualizerRepositoryImpl(this._effects, this._db, this._prefs);

  @override
  Future<AndroidEqualizerParameters> getParameters() => _effects.getParameters();

  @override
  Future<void> setBandGain(int index, double gain) => _effects.setBandGain(index, gain);

  @override
  Future<bool> isEnabled() async {
    return _prefs.getBool(_enabledKey) ?? false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
    await _effects.setEnabled(enabled);
  }

  @override
  Future<void> setLoudnessGain(double gain) => _effects.setLoudnessGain(gain);

  @override
  Future<List<EqualizerPresetModel>> getPresets() => _db.getPresets();

  @override
  Future<void> savePreset(String name, List<double> gains) => _db.savePreset(name, gains);

  @override
  Future<void> deletePreset(int id) => _db.deletePreset(id);
}