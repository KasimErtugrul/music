import 'package:audio_session/audio_session.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

/// Ses odağı (arama, bildirim vb.) ve kulaklık çıkarma olaylarını yönetir.
class AudioSessionDatasource {
  AudioSessionDatasource(this._player);

  final PlayerDataSource _player;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Ses odağı kesintileri
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.pause) {
          _player.pause();
        } else if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(0.3);
        }
      } else {
        if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(1.0);
        }
        // Gün 21: Kesinti bitince çalmaya devam etme seçeneği.
      }
    });

    // Kulaklık çıkarılınca duraklat
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });
  }
}