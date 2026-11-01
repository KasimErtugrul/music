import 'package:get/get.dart';
import 'package:resonance/data/models/waveform_model.dart';
import 'package:resonance/data/repositories/waveform_repository.dart';

class WaveformController extends GetxController {
  final WaveformRepository _repo;
  WaveformController(this._repo);

  final isLoading = false.obs;
  final waveform = Rxn<WaveformModel>();
  
  String? _currentPath;

  Future<void> load(String songPath) async {
    if (_currentPath == songPath) return; // Zaten yüklü
    _currentPath = songPath;
    isLoading.value = true;
    waveform.value = null;

    try {
      final result = await _repo.getWaveform(songPath);
      // Bu arada parça değiştiyse eski hesabın sonucu yenisini ezmesin.
      if (_currentPath == songPath) waveform.value = result;
    } finally {
      if (_currentPath == songPath) isLoading.value = false;
    }
  }

  void clear() {
    _currentPath = null;
    waveform.value = null;
  }
}