import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/theme_presets.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class ThemeGalleryPage extends StatelessWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeGroupColor)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisExtent: 160,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: ThemePresets.all.length,
        itemBuilder: (context, i) {
          final preset = ThemePresets.all[i];
          final isSelected =
              themeCtrl.settings.value.seedColor == preset.seed;

          return InkWell(
            onTap: () => themeCtrl.setSeed(preset.seed),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    preset.seed,
                    Color.lerp(preset.seed, Colors.white, 0.4)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                preset.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}