import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/app.dart';
import 'package:resonance/data/datasources/audio_handler.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => ResonanceAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.resonance.channel.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription: 'Playback controls for Resonance',
      androidNotificationOngoing: true,
    ),
  );

  // `InitialBinding` bu örneği `Get.find<ResonanceAudioHandler>()` ile bulur.
  Get.put<ResonanceAudioHandler>(
    audioHandler as ResonanceAudioHandler,
    permanent: true,
  );

  runApp(const ResonanceApp());
}