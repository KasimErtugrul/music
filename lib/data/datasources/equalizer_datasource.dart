import 'dart:convert';
import 'package:resonance/data/datasources/local/daos/equalizer_preset_dao.dart';
import 'package:resonance/data/models/equalizer_model.dart';

class EqualizerDatasource {
  final EqualizerPresetDao _dao;
  EqualizerDatasource(this._dao);

  Future<List<EqualizerPresetModel>> getPresets() async {
    final rows = await _dao.getAll();
    return rows.map((r) {
      final gains = (jsonDecode(r.bandsJson) as List).cast<num>().map((e) => e.toDouble()).toList();
      return EqualizerPresetModel(id: r.id, name: r.name, gains: gains);
    }).toList();
  }

  Future<void> savePreset(String name, List<double> gains) {
    return _dao.insert(name, jsonEncode(gains));
  }

  Future<void> deletePreset(int id) => _dao.deletePreset(id);
}