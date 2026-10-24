import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:resonance/data/models/equalizer_model.dart';
import 'package:resonance/data/repositories/equalizer_repository.dart';

class BuiltInPreset {
  final String id;
  final List<double> curve; // [Bass, Mid, Treble] (-1.0 to 1.0)
  const BuiltInPreset(this.id, this.curve);
}

class EqualizerController extends GetxController {
  final EqualizerRepository _repo;
  EqualizerController(this._repo);

  final isLoading = true.obs;
  final isEnabled = false.obs;
  final params = Rxn<AndroidEqualizerParameters>();
  final presets = <EqualizerPresetModel>[].obs;
  final loudnessGain = 0.0.obs;

  List<AndroidEqualizerBand> get bands => params.value?.bands ?? [];
  double get minDecibels => params.value?.minDecibels ?? -15.0;
  double get maxDecibels => params.value?.maxDecibels ?? 15.0;

  // Hazır preset tanımları
  final List<BuiltInPreset> builtInPresets = const [
    BuiltInPreset('flat', [0.0, 0.0, 0.0]),
    BuiltInPreset('rock', [0.6, -0.1, 0.5]),
    BuiltInPreset('pop', [0.3, 0.4, 0.2]),
    BuiltInPreset('jazz', [0.4, 0.2, 0.3]),
    BuiltInPreset('classical', [0.2, 0.2, 0.3]),
    BuiltInPreset('bass', [1.0, 0.0, 0.0]),
    BuiltInPreset('treble', [0.0, 0.0, 1.0]),
    BuiltInPreset('vocal', [-0.2, 0.8, 0.2]),
  ];

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoading.value = true;
    try {
      isEnabled.value = await _repo.isEnabled();

      // Parametreleri okumak için ekolayzeri geçici etkinleştir
      await _repo.setEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));

      params.value = await _repo.getParameters().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (params.value == null || params.value!.bands.isEmpty) {
        throw Exception('Not supported');
      }

      presets.assignAll(await _repo.getPresets());
      
      // Kullanıcının önceki tercihini geri yükle
      await _repo.setEnabled(isEnabled.value);
    } catch (e) {
      params.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleEnabled(bool value) async {
    isEnabled.value = value;
    await _repo.setEnabled(value);
  }

  Future<void> updateBand(int index, double gain) async {
    if (params.value == null) return;
    await params.value!.bands[index].setGain(gain);
    params.refresh();
    await _repo.setBandGain(index, gain);
  }

  Future<void> setLoudness(double gain) async {
    loudnessGain.value = gain;
    await _repo.setLoudnessGain(gain);
  }

  Future<void> applyPreset(EqualizerPresetModel preset) async {
    for (var i = 0; i < bands.length && i < preset.gains.length; i++) {
      await updateBand(i, preset.gains[i]);
    }
  }

  Future<void> applyBuiltInPreset(BuiltInPreset preset) async {
    if (params.value == null) return;
    
    final newGains = bands.map((band) {
      // Bas (<250Hz), Orta (250-4000Hz), Tiz (>4000Hz)
      double val;
      if (band.centerFrequency < 250) {
        val = preset.curve[0];
      } else if (band.centerFrequency < 4000) val = preset.curve[1];
      else val = preset.curve[2];

      // -1..1 aralığını cihazın min/max dB değerlerine ölçekle
      if (val > 0) return val * maxDecibels;
      if (val < 0) return val * minDecibels.abs();
      return 0.0;
    }).toList();

    for (var i = 0; i < bands.length; i++) {
      await updateBand(i, newGains[i]);
    }
  }

  Future<void> savePreset(String name) async {
    final currentGains = bands.map((b) => b.gain).toList();
    await _repo.savePreset(name, currentGains);
    presets.assignAll(await _repo.getPresets());
  }

  Future<void> deletePreset(int id) async {
    await _repo.deletePreset(id);
    presets.assignAll(await _repo.getPresets());
  }
}