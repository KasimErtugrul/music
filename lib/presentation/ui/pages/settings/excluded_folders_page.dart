import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';

/// Gün 13: sayfa etkileşimi plana göre yeniden düzenlendi —
/// - Boş durum: ortak [EmptyState] (ikon + başlık + açıklama);
/// - Kaydırarak silme: [Dismissible] (sondan başa kırmızı zemin);
/// - Geri al: silme sonrası SnackBar eylemi klasörü listeye geri ekler.
/// Klasör ekleme/çıkarma kütüphane taramasını tetiklediğinden (controller),
/// geri al da aynı rescan yolunu izler — liste daima diskle tutarlıdır.
class ExcludedFoldersPage extends StatelessWidget {
  const ExcludedFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<ExcludedFoldersController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.excludedFolders)),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.folders.isEmpty) {
          return EmptyState(
            icon: Icons.folder_off_outlined,
            title: l10n.noExcludedFolders,
            message: l10n.excludedFoldersDesc,
          );
        }

        return ListView.builder(
          itemCount: ctrl.folders.length,
          itemBuilder: (context, i) {
            final folder = ctrl.folders[i];
            return Dismissible(
              key: ValueKey<String>(folder.path),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onDismissed: (_) =>
                  _removeWithUndo(context, ctrl, folder.path),
              child: ListTile(
                leading: const Icon(Icons.folder_off),
                title: Text(folder.path,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.getDirectoryPath();
          if (result != null) {
            await ctrl.addFolder(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Sil + geri al. Yıkıcı işlem tek yoldan geçer: kaydırarak silme.
  /// SnackBar'ın eylemi [ExcludedFoldersController.addFolder]'ı çağırır;
  /// bu da taramayı tetiklediği için geri alma gerçek bir kütüphane
  /// güncellemesidir (yalnız listede görünme değil).
  Future<void> _removeWithUndo(
    BuildContext context,
    ExcludedFoldersController ctrl,
    String path,
  ) async {
    final l10n = AppLocalizations.of(context);
    await ctrl.removeFolder(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.excludedFolderRemoved),
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () => ctrl.addFolder(path),
          ),
        ),
      );
  }
}
