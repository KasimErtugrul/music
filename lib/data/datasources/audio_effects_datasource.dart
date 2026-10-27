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

  /// Yalnızca ekolayzer kanalını aç/kapat.
  ///
  /// Görev 2.3 (kullanıcı incelemesi sonucu): Eski sürüm bu metotta
  /// LoudnessEnhancer'ı da birlikte açıp kapatıyordu; sonuçta ekolayzer
  /// kapalıyken ReplayGain tamamen etkisiz kalıyordu. Kanallar artık
  /// bağımsızdır: loudness kanalı [setLoudnessEnabled] ile yönetilir.
  Future<void> setEnabled(bool enabled) async {
    await equalizer.setEnabled(enabled);
  }

  /// Yalnızca LoudnessEnhancer kanalını aç/kapat.
  ///
  /// Sahiplik: PlayerController (ReplayGain, Görev 2.3) ve
  /// EqualizerController (manuel loudness, Görev 2.4) bu kanalı kendi
  /// tercihlerine göre yönetir.
  Future<void> setLoudnessEnabled(bool enabled) async {
    try {
      await loudnessEnhancer.setEnabled(enabled);
    } catch (_) {
      // Bazı cihazlar LoudnessEnhancer'ı desteklemeyebilir, çökmeyi engelle.
    }
  }

  /// Hedef kazancı uygular.
  ///
  /// Birim notu (plan incelemesinde doğrulandı): just_audio'nun Dart API'si
  /// decibel (dB) bekler; Android'e geçişte Java katmanı değeri x100 ile
  /// milibele çevirir. Depodaki eski "just_audio milibel (mB) bekler"
  /// yorumu hatalıydı; ekolayzer sayfasındaki /100 gösterimiyle birleşince
  /// kullanıcı +15 dB isterken çok daha büyük bir kazanç oluşuyordu.
  /// Tüm katmanlarda birim artık dB'dir.
  Future<void> setLoudnessGain(double gainDb) async {
    try {
      await loudnessEnhancer.setTargetGain(gainDb);
    } catch (_) {}
  }
}
