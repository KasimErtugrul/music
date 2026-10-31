// Gün 14: erişilebilirlik taşma taraması.
//
// Şartname: «Sistem yazı ölçeği 1.3 ve uygulama ölçeği 1.4 birlikte: tüm
// ayar sayfalarında taşma taraması» + «TR ve EN metin taşması kontrolü».
//
// Yöntem: app.dart'taki Gün 3 bileşim formülü (sistem × uygulama, 0.5–2.0
// kırpma) birebir taklit edilir: TextScaler.linear(1.3 × 1.4 = 1.82).
// Her ayar sayfası iki dilde (tr, en) pompalanır; ListView'lar tembel
// kurulduğu için TÜM Scrollable'lar art arda sürüklenir ve HER karede
// takeException ile RenderFlex taşması aranır. Ekran dışındaki taşmalar
// yalnızca içerik gerçekten kurulunca ortaya çıktığı için kaydırma şarttır.
//
// Kapsam: ayarlar ana sayfasından ulaşılabilen 14 ayar sayfası. Ekolayzer
// sayfası ayar sayfası değil ses işleme ekranıdır (kendi controller zinciri
// olan ayrı iş) — raporun «Yapılamayanlar» bölümünde belirtilir.
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/core/utils/permission_helper.dart';
import 'package:resonance/data/datasources/auto_backup_storage.dart';
import 'package:resonance/data/datasources/home_widget_datasource.dart';
import 'package:resonance/data/models/app_settings_model.dart';
import 'package:resonance/data/models/backup_model.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/models/library_settings_model.dart';
import 'package:resonance/data/models/playback_settings_model.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/auto_backup_repository.dart';
import 'package:resonance/data/repositories/backup_repository.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/favorite_repository.dart';
import 'package:resonance/data/repositories/history_repository.dart';
import 'package:resonance/data/repositories/home_widget_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/data/repositories/player_repository.dart';
import 'package:resonance/data/repositories/preferences_repository.dart';
import 'package:resonance/data/repositories/queue_state_repository.dart';
import 'package:resonance/data/repositories/settings_repository.dart';
import 'package:resonance/data/repositories/theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/auto_backup_controller.dart';
import 'package:resonance/presentation/controllers/backup_controller.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';
import 'package:resonance/presentation/controllers/favorite_controller.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/controllers/permission_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/sleep_timer_controller.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/pages/backup_page.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/font_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/list_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/player_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_gallery_page.dart';
import 'package:resonance/presentation/ui/pages/settings/audio_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/excluded_folders_page.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/notifications/notification_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/settings_home_page.dart';
import 'package:resonance/presentation/ui/pages/settings/tags_artwork_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/widget_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- mocklar ---------------------------------------------------------------

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockLibraryRepository extends Mock implements LibraryRepository {}

class _MockQueueStateRepository extends Mock implements QueueStateRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockThemeRepository extends Mock implements ThemeRepository {}

class _MockCustomThemeRepository extends Mock
    implements CustomThemeRepository {}

class _MockFavoriteRepository extends Mock implements FavoriteRepository {}

class _MockHomeWidgetRepository extends Mock implements HomeWidgetRepository {}

class _MockHomeWidgetDatasource extends Mock implements HomeWidgetDatasource {}

class _MockBackupRepository extends Mock implements BackupRepository {}

class _MockAutoBackupRepository extends Mock implements AutoBackupRepository {}

class _FakeSettingsRepo implements SettingsRepository {
  @override
  Future<AppSettingsModel> load() async =>
      const AppSettingsModel(languageCode: 'system');

  @override
  Future<void> setString(String key, String value) async {}
}

class _InMemoryExcludedRepo implements ExcludedFolderRepository {
  final List<String> paths;
  _InMemoryExcludedRepo(this.paths);

  @override
  Future<List<ExcludedFolderModel>> getExcludedFolders() async =>
      [for (var i = 0; i < paths.length; i++) ExcludedFolderModel(id: i, path: paths[i])];

  @override
  Future<void> addFolder(String path) async => paths.add(path);

  @override
  Future<void> removeFolder(String path) async => paths.remove(path);
}

SongModel _song(int id, String title) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: title,
      durationMs: 180000,
      sizeBytes: 4000000,
    );

// ---- test düzeneği ---------------------------------------------------------

/// Ayar sayfası ölçeği: sistem 1.3 × uygulama 1.4 = 1.82 (app.dart Gün 3
/// formülünün test karşılığı).
const double _combinedScale = 1.3 * 1.4;

Widget _host(Widget page, Locale locale) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      // app.dart builder'ı gibi bileşik ölçeği uygular:
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_combinedScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: page,
    );

void _setSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Sabit pompalar: pumpAndSettle yerine kullanılır; bildirim sayfasındaki
/// 15 saniyelik saat zamanlayıcısı pumpAndSettle'ı asıya düşürür.
Future<void> _pumps(WidgetTester tester, {int n = 6}) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPlayerRepository playerRepo;
  late _MockLibraryRepository libRepo;
  late _MockThemeRepository themeRepo;
  late _MockFavoriteRepository favRepo;
  late _MockHomeWidgetRepository hwRepo;
  late _MockHomeWidgetDatasource hwDatasource;
  late _MockBackupRepository backupRepo;
  late _MockAutoBackupRepository autoRepo;
  late StreamController<MediaItem?> playerStream;
  late ThemeController themeCtrl;
  late List<String> excludedStore;

  /// ThemeController gövde içinde dispose edildiyse tearDown tekrar
  /// dokunmasın (GetX "used after being disposed" assert'i).
  bool themeCtrlNeedsDispose = false;

  setUpAll(() {
    registerFallbackValue(<SongModel>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(_song(1, 'Fallback'));
    registerFallbackValue(const SongSort());
    registerFallbackValue(const PlaybackSettingsModel());
    registerFallbackValue(const LibrarySettingsModel());
    registerFallbackValue(const ThemeSettings());
    registerFallbackValue(const BackupModel(
      playlists: [],
      favorites: [],
      customThemes: [],
      equalizerPresets: [],
      settings: {},
    ));
  });

  setUp(() {
    Get.testMode = true;
    themeCtrlNeedsDispose = false;

    playerRepo = _MockPlayerRepository();
    libRepo = _MockLibraryRepository();
    themeRepo = _MockThemeRepository();
    favRepo = _MockFavoriteRepository();
    hwRepo = _MockHomeWidgetRepository();
    hwDatasource = _MockHomeWidgetDatasource();
    backupRepo = _MockBackupRepository();
    autoRepo = _MockAutoBackupRepository();
    excludedStore = ['/music/podcast', '/music/kitap'];

    when(() => playerRepo.mediaItemStream)
        .thenAnswer((_) => const Stream<MediaItem?>.empty());
    when(() => playerRepo.queueStream)
        .thenAnswer((_) => const Stream<List<MediaItem>>.empty());
    when(() => playerRepo.playbackStateStream)
        .thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => playerRepo.positionStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => playerRepo.durationStream)
        .thenAnswer((_) => const Stream<Duration?>.empty());
    when(() => playerRepo.errorStream)
        .thenAnswer((_) => const Stream<PlayerException>.empty());
    when(() => playerRepo.position).thenReturn(Duration.zero);
    when(() => playerRepo.currentIndex).thenReturn(0);

    when(() => libRepo.songs(sort: any(named: 'sort')))
        .thenAnswer((_) async => <SongModel>[]);
    when(() => libRepo.artwork(any(), size: any(named: 'size')))
        .thenAnswer((_) async => null);
    when(() => libRepo.rescan()).thenAnswer((_) async {});

    when(() => themeRepo.loadActiveTheme()).thenAnswer((_) async => null);
    when(() => themeRepo.saveActiveTheme(any())).thenAnswer((_) async {});
    when(() => favRepo.watchFavoriteIds())
        .thenAnswer((_) => const Stream<List<int>>.empty());
    when(() => hwRepo.updateWidget(
          title: any(named: 'title'),
          artist: any(named: 'artist'),
          isPlaying: any(named: 'isPlaying'),
          isTransparent: any(named: 'isTransparent'),
        )).thenAnswer((_) async {});
    when(() => hwDatasource.saveArtwork(any())).thenAnswer((_) async {});
    when(() => backupRepo.export()).thenAnswer((_) async => const BackupModel(
          playlists: [],
          favorites: [],
          customThemes: [],
          equalizerPresets: [],
          settings: {},
        ));
    when(() => autoRepo.list()).thenAnswer((_) async => <AutoBackupEntry>[]);
  });

  tearDown(() async {
    if (themeCtrlNeedsDispose) {
      themeCtrlNeedsDispose = false;
      themeCtrl.dispose();
    }
    await playerStream.close();
    Get.reset();
  });

  /// Tüm ayar sayfalarının ihtiyaç duyduğu controller katmanı. Kayıt sırası
  /// önemlidir: SleepTimerController alan başlatıcısında PlayerController
  /// arar, WidgetSettingsPage initState'te HomeWidgetController arar.
  Future<void> seedAll() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'library_settings': '{"scanOnStartup":false,"minDurationSeconds":30}',
    });
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs);

    Get.put<SettingsController>(SettingsController(_FakeSettingsRepo()));
    Get.put<PreferencesController>(PreferencesController(
      PreferencesRepositoryImpl(prefs),
    ));

    playerStream = StreamController<MediaItem?>();
    themeCtrl = ThemeController(themeRepo, playerStream.stream, libRepo);
    Get.put(themeCtrl);
    themeCtrlNeedsDispose = true;
    Get.put<CustomThemeRepository>(_MockCustomThemeRepository());
    when(() => Get.find<CustomThemeRepository>().watchAll())
        .thenAnswer((_) => const Stream<List<CustomThemeModel>>.empty());

    final player = PlayerController(playerRepo, libRepo,
        _MockQueueStateRepository(), _MockHistoryRepository());
    Get.put<PlayerController>(player);

    Get.put<FavoriteController>(FavoriteController(favRepo));
    Get.put<SleepTimerController>(SleepTimerController());
    Get.put<PermissionController>(PermissionController(
      PermissionHelper(sdkIntLoader: () async => 34),
    ));
    Get.put<HomeWidgetController>(HomeWidgetController(
      hwRepo, hwDatasource, player, libRepo, prefs,
    ));
    Get.put<BackupController>(BackupController(backupRepo, libRepo));
    Get.put<AutoBackupController>(AutoBackupController(
      autoRepo: autoRepo,
      backupRepo: backupRepo,
      libraryRepo: libRepo,
      prefs: prefs,
    ));
    Get.put<ExcludedFoldersController>(
      ExcludedFoldersController(_InMemoryExcludedRepo(excludedStore), libRepo),
    );
  }

  /// Sayfayı pompalar, ardından tüm Scrollable'ları sırayla sürükleyerek
  /// tembel içeriği kurar; HER karede taşma istisnası aranır. Hata bulunursa
  /// [failures]'a yazılır ve tarama devam eder — tek koşuda tüm taşmalar
  /// listelenir. informationCollector çıktısı suçlu widget'ı verir.
  Future<void> scanPage(
    WidgetTester tester,
    Widget page,
    String label,
    Locale locale,
    Map<String, String> failures,
  ) async {
    final infoBuf = <String>[];
    final prevHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      // informationCollector sıfır argümanlı Diagnosticable döndüren
      // fonksiyondur; RenderFlex taşmasında suçlu widget'ı "The relevant
      // error-causing widget was: …" satırıyla bildirir.
      final collected = details.informationCollector?.call();
      infoBuf.add(collected?.toString() ?? '');
      prevHandler?.call(details);
    };
    void check(String where) {
      final ex = tester.takeException();
      if (ex != null) {
        final info = infoBuf.isNotEmpty ? infoBuf.removeLast() : '';
        failures['$label (${locale.languageCode}) — $where'] =
            '$ex\n$info';
      }
    }

    try {
      _setSurface(tester);
      await tester.pumpWidget(_host(page, locale));
      await _pumps(tester);
      check('ilk kare');

      const rounds = 10;
      for (var round = 0; round < rounds; round++) {
        final widgets =
            find.byType(Scrollable).evaluate().map((e) => e.widget).toList();
        for (var i = 0; i < widgets.length; i++) {
          final finder = find.byWidget(widgets[i]);
          if (finder.hitTestable().evaluate().isEmpty) continue;
          await tester.drag(finder, const Offset(0, -600));
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
          check('Scrollable #$i, tur $round');
        }
        if (widgets.isEmpty) break;
      }
    } finally {
      FlutterError.onError = prevHandler;
    }
  }

  List<(String, Widget)> pages() => <(String, Widget)>[
        ('Ayarlar ana sayfası', const SettingsHomePage()),
        ('Çalma', const PlaybackSettingsPage()),
        ('Ses', const AudioSettingsPage()),
        ('Kitaplık', const LibrarySettingsPage()),
        ('Etiketler ve kapak', const TagsArtworkSettingsPage()),
        ('Widget', const WidgetSettingsPage()),
        ('Bildirim önizlemesi', const NotificationSettingsPage()),
        ('Görünüm', const ThemeGalleryPage()),
        ('Yazı tipi', const FontSettingsPage()),
        ('Oynatıcı stili', const PlayerStylePage()),
        ('Liste stili', const ListStylePage()),
        ('Dışlanan klasörler', const ExcludedFoldersPage()),
        ('Hakkında', const AboutPage()),
        ('Yedekleme', const BackupPage()),
      ];

    testWidgets('TR: 14 ayar sayfası 1.3×1.4 ölçekte taşmasız çizilir',
      (tester) async {
    await seedAll();
    final failures = <String, String>{};
    for (final (label, page) in pages()) {
      await scanPage(tester, page, label, const Locale('tr'), failures);
    }
    // ThemeController'ın dakikalık zamanlayıcısı test gövdesi içinde
    // (FakeAsync bölgesi) kurulur; invariyant denetimi gövde sonunda
    // çalıştığı için iptal gövde içinde yapılmalıdır.
    themeCtrl.dispose();
    themeCtrlNeedsDispose = false;
    expect(failures, isEmpty, reason: failures.entries.map((e) => '${e.key}\n${e.value}').join('\n\n———\n\n'));
  });

  testWidgets('EN: 14 ayar sayfası 1.3×1.4 ölçekte taşmasız çizilir',
      (tester) async {
    await seedAll();
    final failures = <String, String>{};
    for (final (label, page) in pages()) {
      await scanPage(tester, page, label, const Locale('en'), failures);
    }
    themeCtrl.dispose();
    themeCtrlNeedsDispose = false;
    expect(failures, isEmpty, reason: failures.entries.map((e) => '${e.key}\n${e.value}').join('\n\n———\n\n'));
  });
}
