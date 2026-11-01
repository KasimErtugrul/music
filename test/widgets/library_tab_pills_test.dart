// Gün 17.8: Kitaplık sekme rozetlerinin canlı sayım testleri.
//
// Kapsam:
// - Rozetler LibraryController'daki gerçek listelerle çizilir (3 şarkı → «3»)
// - Liste değişince rozet KENDİLİĞİNDEN güncellenir (eski sürümde açılışta
//   «0»'da donuk kalıyordu; Obx yoktu)
// - Hap düğmesine dokunma TabController'ı o sekmeye taşır
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/song_model.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/ui/widgets/library_tab_pills.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

SongModel _song(int id) => SongModel(
      id: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/music/$id.mp3',
      title: 'Şarkı $id',
      durationMs: 180000,
      sizeBytes: 4000000,
    );

/// TabController vsync gerektirir; hap düğmelerini sade bir ev sahibinde
/// çiziyoruz (SongsView/PlayerController zinciri burada gereksizdir).
class _Host extends StatefulWidget {
  const _Host({required this.onCreated, required this.builder});

  final ValueChanged<TabController> onCreated;
  final Widget Function(BuildContext context, TabController controller) builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    widget.onCreated(_tabController);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _tabController);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLibraryRepository libRepo;
  late LibraryController controller;
  late TabController tabController;

  setUpAll(() {
    registerFallbackValue(const SongSort());
  });

  setUp(() {
    Get.testMode = true;
    libRepo = _MockLibraryRepository();
    when(() => libRepo.songs(sort: any(named: 'sort')))
        .thenAnswer((_) async => <SongModel>[_song(1), _song(2), _song(3)]);
    when(() => libRepo.letterOffsets(any()))
        .thenAnswer((_) async => <String, int>{});
    when(() => libRepo.albums()).thenAnswer((_) async => const []);
    when(() => libRepo.artists()).thenAnswer((_) async => const []);
    when(() => libRepo.genres()).thenAnswer((_) async => const []);
    when(() => libRepo.folders()).thenAnswer((_) async => const []);
    when(() => libRepo.incrementalScan(
          triggerPlatformScan: any(named: 'triggerPlatformScan'),
        )).thenAnswer((_) async => LibraryScanDelta(changed: false));
    controller = Get.put(LibraryController(libRepo));
  });

  tearDown(() async {
    await Get.delete<LibraryController>(force: true);
    Get.reset();
  });

  Future<void> pumpPills(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Host(
          onCreated: (c) => tabController = c,
          builder: (context, ctrl) => Scaffold(
            body: LibraryTabPills(controller: controller, tabController: ctrl),
          ),
        ),
      ),
    );
    // onInit -> loadAll mikro görevleri ve Obx güncellemesi otursun.
    await tester.pump();
  }

  testWidgets('rozetler gerçek liste sayılarıyla çizilir', (tester) async {
    await pumpPills(tester);

    expect(find.text('3'), findsOneWidget); // Şarkılar
    // Albümler/Sanatçılar/Türler/Klasörler boş: dört «0» rozeti.
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('liste değişince rozet kendiliğinden güncellenir',
      (tester) async {
    await pumpPills(tester);
    expect(find.text('3'), findsOneWidget);

    controller.songs.add(_song(4));
    await tester.pump();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('hap düğmesine dokunma sekmeyi değiştirir', (tester) async {
    await pumpPills(tester);
    expect(tabController.index, 0);

    await tester.tap(find.text('Albümler'));
    await tester.pumpAndSettle();

    expect(tabController.index, 1);
  });
}