import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/app.dart';
import 'package:resonance/core/bindings/initial_binding.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/datasources/player_datasource.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs, permanent: true);

    Get.put<SettingsRepository>(SettingsRepositoryImpl(prefs), permanent: true);
    Get.put<SettingsController>(
      SettingsController(Get.find<SettingsRepository>()),
      permanent: true,
    );
    Get.put<ThemeRepository>(ThemeRepositoryImpl(prefs), permanent: true);
    Get.put<PreferencesRepository>(
      PreferencesRepositoryImpl(prefs),
      permanent: true,
    );
    Get.put<PreferencesController>(
      PreferencesController(Get.find<PreferencesRepository>()),
      permanent: true,
    );

    // --- Ses efektleri ---
    final audioEffects = AudioEffectsDatasource();
    Get.put<AudioEffectsDatasource>(audioEffects, permanent: true);

    final playerSource = PlayerDataSource(audioEffects);
    Get.put<PlayerDataSource>(playerSource, permanent: true);

    audioHandler = await AudioService.init(
      builder: () => ResonanceAudioHandler(
        source: playerSource,
        // audio_service yalnızca file:// ve content:// artUri'yi yerel okur; diğer şemaları
        // HTTP indirici (flutter_cache_manager) ile almaya çalışır. `data:` URI bildirimde
        // kapak göstermez (ve INTERNET izni de yok). Bu yüzden JPEG dosyaya yazılır.
        artResolver: (songUri) async {
          final id = int.tryParse(songUri.split('/').last);
          if (id == null) return null;
          final dir = Directory('${(await getTemporaryDirectory()).path}/notif_art');
          final file = File('${dir.path}/$id.jpg');
          if (await file.exists() && await file.length() > 0) {
            return Uri.file(file.path);
          }
          final bytes = await Get.find<LibraryRepository>().artwork(id, size: 512);
          if (bytes == null || bytes.isEmpty) return null;
          await dir.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
          return Uri.file(file.path);
        },
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.resonance.channel.audio',
        androidNotificationChannelName: 'Playback',
        androidNotificationChannelDescription: 'Playback controls',
        // false: duraklatılınca bildirim kaydırılıp kapatılabilir. `true` iken
        // duraklatılmış kart bile kaldırılamıyordu.
        androidNotificationOngoing: false,
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );
    Get.put<ResonanceAudioHandler>(
      audioHandler as ResonanceAudioHandler,
      permanent: true,
    );

    InitialBinding().dependencies();
    Get.put<SleepTimerController>(SleepTimerController(), permanent: true);

    Get.put<ThemeController>(
      ThemeController(
        Get.find<ThemeRepository>(),
        Get.find<PlayerController>().currentItem.stream,
        Get.find<LibraryRepository>(),
      ),
      permanent: true,
    );

    runApp(const ResonanceApp());
  } catch (e, st) {
    runApp(_StartupErrorApp(error: e, stack: st));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.stack});
  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uygulama başlatılamadı',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                const SizedBox(height: 12),
                const Text('Hata:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText('$error'),
                const SizedBox(height: 16),
                const Text('Stack:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText('$stack',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}