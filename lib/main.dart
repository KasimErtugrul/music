import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:resonance/app.dart';
import 'package:resonance/data/datasources/audio_handler.dart';

/// Gün 7: arka plan oynatma köprüsü. Gün 8'de `PlayerRepository` bunu
/// kullanacak; şimdilik global tutuluyor.
late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => ResonanceAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.resonance.channel.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription:
          'Playback controls for Resonance',
      androidNotificationOngoing: true,
      // Uygulama görevden kaldırılınca servisi durdurmak için Gün 21'de
      // ilgili parametre DOĞRULANIP eklenecek.
    ),
  );

  runApp(const ResonanceApp());
}