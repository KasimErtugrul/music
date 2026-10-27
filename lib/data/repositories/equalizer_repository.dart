import 'dart:convert';
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
  Future<void> setLoudnessEnabled(bool enabled);
  Future<List<EqualizerPresetModel>> getPresets();
  Future<void> savePreset(String name, List<double> gains);
  Future<void> deletePreset(int id);

  /// Görev 2.4: bant kazançlarının kalıcılığı (JSON, dB cinsinden).
  List<double>? loadGains();
  Future<void> saveGains(List<double> gains);

  /// Görev 2.4: manuel loudness değerinin kalıcılığı (dB cinsinden).
  double? loadLoudness();
  Future<void> saveLoudness(double gain);
}

class EqualizerRepositoryImpl implements EqualizerRepository {
  final AudioEffectsDatasource _effects;
  final EqualizerDatasource _db;
  final SharedPreferences _prefs;

  static const _enabledKey = 'equalizer_enabled';

  // Görev 2.4: kalıcılık anahtarları. Kazançlar bant sırasına göre dB
  // değerleri listesi; loudness tek bir dB değeridir. Eski sürümde bu
  // değerler hiç yazılmıyordu; anahtarlar yeni kurulumda boş başlar.
  static const _gainsKey = 'equalizer_gains';
  static const _loudnessKey = 'equalizer_loudness';

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
    // Görev 2.3: artık yalnızca ekolayzer kanalını etkiler; loudness
    // kanalı setLoudnessEnabled ile bağımsız yönetilir.
    await _effects.setEnabled(enabled);
  }

  @override
  Future<void> setLoudnessEnabled(bool enabled) =>
      _effects.setLoudnessEnabled(enabled);

  @override
  Future<void> setLoudnessGain(double gain) => _effects.setLoudnessGain(gain);

  @override
  Future<List<EqualizerPresetModel>> getPresets() => _db.getPresets();

  @override
  Future<void> savePreset(String name, List<double> gains) => _db.savePreset(name, gains);

  @override
  Future<void> deletePreset(int id) => _db.deletePreset(id);

  @override
  List<double>? loadGains() {
    final raw = _prefs.getString(_gainsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<num>().map((e) => e.toDouble()).toList();
    } catch (_) {
      // Bozuk JSON: kalıcılık hiç yazılmamış gibi davran.
      return null;
    }
  }

  @override
  Future<void> saveGains(List<double> gains) =>
      _prefs.setString(_gainsKey, jsonEncode(gains));

  @override
  double? loadLoudness() => _prefs.getDouble(_loudnessKey);

  @override
  Future<void> saveLoudness(double gain) => _prefs.setDouble(_loudnessKey, gain);
}
