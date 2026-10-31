// Gün 13: Dışlanan klasörler sayfasının etkileşim testleri.
//
// Kapsam:
// - Boş liste: ortak EmptyState (ikon + başlık + açıklama)
// - Kaydırarak silme (Dismissible, sondan başa) listeyi ve diski günceller
// - Geri al SnackBar eylemi klasörü listeye geri ekler (rescan yoluyla)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resonance/data/models/excluded_folder_model.dart';
import 'package:resonance/data/repositories/excluded_folder_repository.dart';
import 'package:resonance/data/repositories/library_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/excluded_folders_page.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

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

class _MockLibraryRepository extends Mock implements LibraryRepository {}

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> store;
  late _MockLibraryRepository libRepo;

  setUp(() {
    Get.testMode = true;
    store = [];
    libRepo = _MockLibraryRepository();
    when(() => libRepo.rescan()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await Get.delete<ExcludedFoldersController>(force: true);
    Get.reset();
  });

  testWidgets('boş liste: EmptyState başlık ve açıklamayla çizilir',
      (tester) async {
    Get.put(ExcludedFoldersController(
      _InMemoryExcludedRepo(store),
      libRepo,
    ));

    await tester.pumpWidget(_host(const ExcludedFoldersPage()));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Hariç tutulan klasör yok'), findsOneWidget);
    expect(find.text('Kütüphaneden hariç tutulan klasörler'), findsOneWidget);
  });

  testWidgets('kaydırarak sil: listeden ve diskten kalkar', (tester) async {
    store.addAll(['/music/klassik', '/music/podcast']);
    Get.put(ExcludedFoldersController(
      _InMemoryExcludedRepo(store),
      libRepo,
    ));

    await tester.pumpWidget(_host(const ExcludedFoldersPage()));
    await tester.pumpAndSettle();

    expect(find.text('/music/podcast'), findsOneWidget);

    await tester.drag(find.text('/music/podcast'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(store, ['/music/klassik']);
    expect(find.text('/music/podcast'), findsNothing);
    verify(() => libRepo.rescan()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('geri al: SnackBar eylemi klasörü geri ekler', (tester) async {
    store.addAll(['/music/klassik', '/music/podcast']);
    Get.put(ExcludedFoldersController(
      _InMemoryExcludedRepo(store),
      libRepo,
    ));

    await tester.pumpWidget(_host(const ExcludedFoldersPage()));
    await tester.pumpAndSettle();

    await tester.drag(find.text('/music/podcast'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Klasör hariç tutma listesinden kaldırıldı'),
        findsOneWidget);

    await tester.tap(find.text('Geri Al'));
    await tester.pumpAndSettle();

    expect(store, ['/music/klassik', '/music/podcast']);
    expect(find.text('/music/podcast'), findsOneWidget);
  });
}
