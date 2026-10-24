import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/app.dart';
import 'package:resonance/core/bindings/initial_binding.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/player_datasource.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();

    // ÇÖZÜM BURADA: SharedPreferences'ı GetX'e kaydediyoruz
    Get.put<SharedPreferences>(prefs, permanent: true);

    Get.put<SettingsRepository>(SettingsRepositoryImpl(prefs), permanent: true);
    Get.put<SettingsController>(SettingsController(Get.find<SettingsRepository>()), permanent: true);
    Get.put<ThemeRepository>(ThemeRepositoryImpl(prefs), permanent: true);
    Get.put<PreferencesRepository>(PreferencesRepositoryImpl(prefs), permanent: true);
    Get.put<PreferencesController>(PreferencesController(Get.find<PreferencesRepository>()), permanent: true);

    // --- SES EFEKTLERİ VE OYNATICI ---
    final audioEffects = AudioEffectsDatasource();
    Get.put<AudioEffectsDatasource>(audioEffects, permanent: true);
    
    final playerSource = PlayerDataSource(audioEffects);
    Get.put<PlayerDataSource>(playerSource, permanent: true);
    // ---------------------------------

    audioHandler = await AudioService.init(
      builder: () => ResonanceAudioHandler(
        source: playerSource,
        artResolver: (songUri) async {
          final libRepo = Get.find<LibraryRepository>();
          final id = int.tryParse(songUri.split('/').last);
          if (id == null) return null;
          final bytes = await libRepo.artwork(id);
          if (bytes == null) return null;
          return Uri.dataFromBytes(bytes); 
        },
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.resonance.channel.audio',
        androidNotificationChannelName: 'Playback',
        androidNotificationChannelDescription: 'Playback controls',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    Get.put<ResonanceAudioHandler>(audioHandler as ResonanceAudioHandler, permanent: true);

    InitialBinding().dependencies();

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

// _StartupErrorApp sınıfı aynı kalıyor...
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
                const Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hata:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText('$error'),
                const SizedBox(height: 16),
                const Text(
                  'Stack:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText('$stack', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
