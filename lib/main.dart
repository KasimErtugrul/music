import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resonance/app.dart';
import 'package:resonance/core/bindings/initial_binding.dart';
import 'package:resonance/core/errors/app_logger.dart';
import 'package:resonance/data/datasources/audio_effects_datasource.dart';
import 'package:resonance/data/datasources/audio_handler.dart';
import 'package:resonance/data/datasources/auto_browse_delegate.dart';
import 'package:resonance/data/datasources/player_datasource.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/playlist_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resonance/core/settings/settings_key_migration.dart';

late final AudioHandler audioHandler;

/// Aşama 5: bildirim kartı ve Android Auto düğümleri için PAYLAŞILAN kapak
/// çözücüsü. artworkSongId → file:// Uri (temp önbellek jpg'si).
/// audio_service yalnızca file:// ve content:// artUri'yi yerel okur;
/// JPEG dosyaya yazılır (aynı mekanizma Görev 1.2'den beri bildirimde
/// kullanılıyor). Hata daima null döner; Auto düğümü kapsız listelenir.
Future<Uri?> artworkToFile(int id) async {
  try {
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
  } catch (_) {
    return null;
  }
}

/// Android Auto ayrı süreçtir; özel cache'teki file:// yolunu okuyamaz.
/// ArtworkProvider kapağı content:// ile sunar.
Future<Uri?> autoArtworkUri(int id) async =>
    Uri.parse('content://com.developfly.resonance.artwork/art/$id');

/// Aşama 5: Android Auto düğüm etiketleri için yerelleştirme çözücüsü.
/// UI hazırken gerçek locale'den; hazır değilken (arka plan motoru) ayar
/// dili tr ise Türkçe, değilse İngilizce döner. Hiçbir hata Auto sorgusunu
/// engellememeli; her durumda bir AppLocalizations dönmelidir.
AppLocalizations _autoL10n() {
  try {
    final ctx = Get.context;
    if (ctx != null) {
      final fromContext = Localizations.of<AppLocalizations>(
        ctx,
        AppLocalizations,
      );
      if (fromContext != null) return fromContext;
    }
  } catch (_) {}
  try {
    final lang = Get.find<SettingsController>().settings.value?.languageCode;
    if (lang == 'tr') return lookupAppLocalizations(const Locale('tr'));
  } catch (_) {}
  return lookupAppLocalizations(const Locale('en'));
}

Future<void> main() async {
  // Tüm yakalanmamış hatalar tek merkezi günlükçüye akar. Üç katman:
  // Flutter çerçevesi, platform/asenkron ve zone. Binding ve runApp aynı
  // zone içinde olmalıdır.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _installGlobalErrorHandlers();
      await _bootstrap();
    },
    (error, stack) => AppLog.error(error, stack, source: 'zone'),
  );
}

void _installGlobalErrorHandlers() {
  // Release'te debugPrint çıktısı (logcat sızıntısı) susturulur.
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  FlutterError.onError = (details) {
    AppLog.error(details.exception, details.stack, source: 'flutter');
    if (kDebugMode) FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error(error, stack, source: 'platform');
    return true; // işlendi: süreç düşmez
  };

  // Release'te widget hatası gri kutu / ham metin yerine nötr bir boşluk.
  if (!kDebugMode) {
    ErrorWidget.builder = (details) => const SizedBox.shrink();
  }
}

Future<void> _bootstrap() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs, permanent: true);
        // Gün 10: prefs anahtar geçişi. Harita bugün boş (bkz.
    // SettingsKeyMigration belgesi); işlev hiçbir koşulda fırlatmaz ve
    // açılışı engellemez. Tüm repolardan ÖNCE çalışır: hiçbir okuyucu
    // eski anahtar altında kalmış bir tercihe rastlamaz.
    await SettingsKeyMigration.migrate(prefs);

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
        // Görev 1.2: "Kulaklık çıkınca duraklat" kararı olay anında canlı
        // tercihten okunur. PreferencesController bu noktadan ÖNCE kalıcı
        // olarak kaydedildiği için getter güvenle bağlanabilir; ayar
        // değiştiğinde handler'ın yeniden kurulması gerekmez.
        shouldPauseOnUnplug: () =>
            Get.find<PreferencesController>().playback.value.pauseOnHeadphone,
        // audio_service yalnızca file:// ve content:// artUri'yi yerel okur; diğer şemaları
        // HTTP indirici (flutter_cache_manager) ile almaya çalışır. `data:` URI bildirimde
        // kapak göstermez (ve INTERNET izni de yok). Bu yüzden JPEG dosyaya yazılır.
        artResolver: (songUri) async {
          final id = int.tryParse(songUri.split('/').last);
          if (id == null) return null;
          return artworkToFile(id);
        },
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.developfly.resonance.channel.audio',
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

    // Aşama 5: Android Auto göz atma delegesi. InitialBinding tüm repoları
    // kaydettikten sonra bağlanır; Auto sorguları artık canlı kütüphaneyi
    // çeker. Delege bağlanana kadar Auto sorguları güvenli boş döner.
    Get.find<ResonanceAudioHandler>().attachAutoBrowse(
      AutoBrowseDelegate(
        library: Get.find<LibraryRepository>(),
        playlists: Get.find<PlaylistRepository>(),
        favorites: Get.find<FavoriteRepository>(),
        player: Get.find<PlayerController>(),
        l10n: _autoL10n,
        artResolver: autoArtworkUri, // eskisi: artworkToFile
      ),
    );

    Get.put<SleepTimerController>(SleepTimerController(), permanent: true);

    Get.put<ThemeController>(
      ThemeController(
        Get.find<ThemeRepository>(),
        Get.find<PlayerController>().currentItem.stream,
        Get.find<LibraryRepository>(),
      ),
      permanent: true,
    );

    // Aşama 6: otomatik yedekleme zamanlayıcısı. Açılışı BLOKLAMAZ;
    // ilk açılışta hemen, sonrasında sıklık süresi (günlük/haftalık) dolduğunda
    // arka planda yedek alır. Hata fırlatmaz.
    unawaited(Get.find<AutoBackupController>().ensureScheduledBackup());

    runApp(const ResonanceApp());
  } catch (e, st) {
    AppLog.error(e, st, source: 'startup');
    runApp(_StartupErrorApp(error: e, stack: st));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.stack});
  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    // Release'te ham hata ve yığın izi kullanıcıya gösterilmez (yalnızca
    // günlüğe yazılır). Debug'ta geliştirici için ayrıntı korunur.
    final lang = PlatformDispatcher.instance.locale.languageCode;
    final isTr = lang == 'tr';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Uygulama başlatılamadı' : 'The app could not start',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isTr
                      ? 'Beklenmeyen bir sorun oluştu. Lütfen uygulamayı '
                          'kapatıp yeniden açın.'
                      : 'Something went wrong. Please close the app and '
                          'open it again.',
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  SelectableText('$error'),
                  const SizedBox(height: 8),
                  SelectableText('$stack', style: const TextStyle(fontSize: 11)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
