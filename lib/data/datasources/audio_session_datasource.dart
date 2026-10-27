import 'package:audio_session/audio_session.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

/// Ses odağı (arama, bildirim vb.) ve kulaklık çıkarma olaylarını yönetir.
///
/// Görev 1.2: Kulaklık çıkarma dinleyicisi artık koşulsuz değil. Olay anında
/// [shouldPauseOnUnplug] göstergeyi okur ve yalnızca tercih açıksa duraklatır.
/// Fonksiyon göstergeşi kullanmak, ayar değiştiğinde dinleyicinin yeniden
/// kurulmasını gerektirmez; karar her olay anında güncel tercihi okur.
class AudioSessionDatasource {
  AudioSessionDatasource(this._player, {required this.shouldPauseOnUnplug});

  final PlayerDataSource _player;

  /// Olay anında "Kulaklık çıkınca duraklat" tercihinin güncel değerini okur.
  /// main.dart'ta PreferencesController, AudioService.init'ten ÖNCE kalıcı
  /// olarak kaydedildiği için gösterge güvenle bağlanabilir.
  final bool Function() shouldPauseOnUnplug;

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

    // Kulaklık çıkarılınca duraklat — yalnızca ayar açıksa (Görev 1.2)
    session.becomingNoisyEventStream.listen((_) {
      if (shouldPauseOnUnplug()) _player.pause();
    });
  }
}
