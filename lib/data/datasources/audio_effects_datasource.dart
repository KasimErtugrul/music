import 'package:just_audio/just_audio.dart';

class AudioEffectsDatasource {
  final AndroidEqualizer equalizer;
  final AndroidLoudnessEnhancer loudnessEnhancer;

  AudioEffectsDatasource()
      : equalizer = AndroidEqualizer(),
        loudnessEnhancer = AndroidLoudnessEnhancer();

  AudioPipeline get pipeline => AudioPipeline(
        androidAudioEffects: [equalizer, loudnessEnhancer],
      );

  Future<AndroidEqualizerParameters> getParameters() async {
    return await equalizer.parameters;
  }

  Future<void> setBandGain(int index, double gain) async {
    final params = await equalizer.parameters;
    if (index < params.bands.length) {
      await params.bands[index].setGain(gain);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await equalizer.setEnabled(enabled);
    try {
      // Ses yükselticiyi de aç/kapat
      await loudnessEnhancer.setEnabled(enabled);
    } catch (_) {
      // Bazı cihazlar LoudnessEnhancer'ı desteklemeyebilir, çökmeyi engelle.
    }
  }

  Future<void> setLoudnessGain(double gain) async {
    try {
      // just_audio milibel (mB) bekler. 100 mB = 1 dB.
      await loudnessEnhancer.setTargetGain(gain);
    } catch (_) {}
  }
}