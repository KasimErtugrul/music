import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/excluded_folders_controller.dart';

class ExcludedFoldersPage extends StatelessWidget {
  const ExcludedFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = Get.find<ExcludedFoldersController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.excludedFolders)),
      body: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        
        if (ctrl.folders.isEmpty) {
          return Center(child: Text(l10n.noExcludedFolders));
        }

        return ListView.builder(
          itemCount: ctrl.folders.length,
          itemBuilder: (context, i) {
            final folder = ctrl.folders[i];
            return ListTile(
              leading: const Icon(Icons.folder_off),
              title: Text(folder.path, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => ctrl.removeFolder(folder.path),
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
}