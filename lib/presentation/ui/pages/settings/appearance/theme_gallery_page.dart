import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/core/theme/theme_presets.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/custom_theme_editor_page.dart';
import 'package:share_plus/share_plus.dart';

class ThemeGalleryPage extends StatelessWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();
    final customRepo = Get.find<CustomThemeRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themeGroupColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Advanced theme settings',
            onPressed: () => Get.toNamed(AppRoutes.themeSettings),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Theme',
            onPressed: () => _importTheme(context, themeCtrl),
          ),
        ],
      ),
      body: Obx(() {
        final current = themeCtrl.settings.value;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Presets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final preset = ThemePresets.all[i];
                    final isSelected = current.seedColor == preset.seed;
                    return _ThemeCard(
                      name: preset.name,
                      color: preset.seed,
                      isSelected: isSelected,
                      onTap: () {
                        debugPrint(
                          '[ThemeGallery] preset tapped: ${preset.name} '
                          '(0x${preset.seed.value.toRadixString(16)})',
                        );
                        themeCtrl.setSeed(preset.seed);
                      },
                    );
                  },
                  childCount: ThemePresets.all.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom Themes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          Get.to(() => const CustomThemeEditorPage()),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<CustomThemeModel>>(
              stream: customRepo.watchAll(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No custom themes yet.'),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisExtent: 160,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final theme = snapshot.data![i];
                        return _ThemeCard(
                          name: theme.name,
                          color: theme.settings.seedColor,
                          isSelected: false,
                          onTap: () {
                            debugPrint(
                              '[ThemeGallery] custom theme tapped: ${theme.name}',
                            );
                            themeCtrl.setSettings(theme.settings);
                          },
                          onLongPress: () =>
                              _showThemeOptions(context, theme, customRepo),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      }),
    );
  }

  void _showThemeOptions(
    BuildContext context,
    CustomThemeModel theme,
    CustomThemeRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => CustomThemeEditorPage(existingTheme: theme));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              final jsonStr = jsonEncode(theme.settings.toJson());
              SharePlus.instance.share(ShareParams(text: jsonStr));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await repo.deleteTheme(theme.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importTheme(
    BuildContext context,
    ThemeController themeCtrl,
  ) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;
    final path = files.first.path;
    if (path == null) return;

    final file = File(path);
    final content = await file.readAsString();

    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final settings = ThemeSettings.fromJson(map);
      themeCtrl.setSettings(settings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme imported!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid theme file!')),
        );
      }
    }
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.white, 0.4)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black54),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}