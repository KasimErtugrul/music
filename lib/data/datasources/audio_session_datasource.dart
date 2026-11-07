import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:resonance/data/datasources/player_datasource.dart';
import 'package:resonance/data/datasources/volume_coordinator.dart';

/// Ses odağı (arama, bildirim vb.) ve kulaklık çıkarma olaylarını yönetir.
///
/// Görev 1.2: Kulaklık çıkarma dinleyicisi artık koşulsuz değil. Olay anında
/// [shouldPauseOnUnplug] göstergeyi okur ve yalnızca tercih açıksa duraklatır.
/// Fonksiyon göstergeşi kullanmak, ayar değiştiğinde dinleyicinin yeniden
/// kurulmasını gerektirmez; karar her olay anında güncel tercihi okur.
class AudioSessionDatasource {
  AudioSessionDatasource(
    this._player, {
    required this.shouldPauseOnUnplug,
    required this.volume,
  });

  final PlayerDataSource _player;

  /// FAZ 2 (K1): ses tek sahipliği. Duck, ham setVolume YAZMAZ; ses tek
  /// sahibi koordinatörün duck katmanına yazar. Eski «mevcut sesi sakla /
  /// geri yükle» modeli kaldırıldı: o model bayat değer saklıyor, duck
  /// sırasında kullanıcının ses değişikliğini eziyor ve rampa/uyku
  /// sönümüyle çakışıyordu. Katman modelinde duck yalnızca kendi
  /// çarpanını değiştirir; kesinti bittiğinde 1.0'a dönmek diğer
  /// katmanların (kullanıcı sesi, rampa, uyku sönümü) değerlerini
  /// bozmaz.
  final VolumeCoordinator volume;

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
        if (event.type == AudioInterruptionType.duck) {
          // FAZ 2: duck bir katmandır — kullanıcı sesini saklamaya/geri
          // yüklemeye gerek kalmaz; çarpım zaten kullanıcının tercihini
          // korur. Tekrar duck gelmesi ayırt etmez (çarpan ayarlanır).
          unawaited(volume.setDuckFactor(0.3));
        } else {
          // pause ve unknown: ikisi de duraklatır.
          _player.pause();
        }
      } else {
        if (event.type == AudioInterruptionType.duck) {
          unawaited(volume.setDuckFactor(1.0));
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
