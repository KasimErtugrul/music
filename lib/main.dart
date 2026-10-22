import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/app.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Gün 17
  Get.put<SettingsRepository>(
    SettingsRepositoryImpl(prefs),
    permanent: true,
  );
  Get.put<SettingsController>(
    SettingsController(Get.find<SettingsRepository>()),
    permanent: true,
  );

  // Gün 18: Tek seferlik tema controller'ı
  Get.put<ThemeController>(ThemeController(), permanent: true);

  // Gün 7
  audioHandler = await AudioService.init(
    builder: () => ResonanceAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.resonance.channel.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription: 'Playback controls for Resonance',
      androidNotificationOngoing: true,
    ),
  );

  Get.put<ResonanceAudioHandler>(
    audioHandler as ResonanceAudioHandler,
    permanent: true,
  );

  runApp(const ResonanceApp());
}