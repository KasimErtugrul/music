import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/app.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/core/bindings/initial_binding.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 1. Settings
  Get.put<SettingsRepository>(
    SettingsRepositoryImpl(prefs),
    permanent: true,
  );
  Get.put<SettingsController>(
    SettingsController(Get.find<SettingsRepository>()),
    permanent: true,
  );

  // 2. ThemeRepository (SettingsRepository'den bağımsız)
  Get.put<ThemeRepository>(
    ThemeRepositoryImpl(prefs),
    permanent: true,
  );

  // 3. AudioHandler (önce AudioService.init)
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

  // 4. InitialBinding (LibraryRepository, PlayerController, QueueState vs.)
  //    ThemeController'ın bağımlılıklarının hazır olması için BURADA çalıştır.
  InitialBinding().dependencies();

  // 5. ThemeController (artık PlayerController ve LibraryRepository hazır)
  Get.put<ThemeController>(
    ThemeController(
      Get.find<ThemeRepository>(),
      Get.find<PlayerController>(),
      Get.find<LibraryRepository>(),
    ),
    permanent: true,
  );

  runApp(const ResonanceApp());
}