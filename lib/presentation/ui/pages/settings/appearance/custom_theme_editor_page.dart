import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_editor_controller.dart';
import 'package:resonance/presentation/ui/widgets/color_picker_sheet.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';

class CustomThemeEditorPage extends StatefulWidget {
  const CustomThemeEditorPage({super.key, this.existingTheme});
  final CustomThemeModel? existingTheme;

  @override
  State<CustomThemeEditorPage> createState() => _CustomThemeEditorPageState();
}

class _CustomThemeEditorPageState extends State<CustomThemeEditorPage> {
  late final ThemeEditorController controller;
  late final TextEditingController nameCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ThemeEditorController(Get.find<CustomThemeRepository>()),
      permanent: false,
    );
    if (widget.existingTheme != null) {
      controller.initForEdit(widget.existingTheme!);
    }
    nameCtrl = TextEditingController(text: controller.name.value);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    Get.delete<ThemeEditorController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTheme == null ? l10n.themeCustom : 'Edit Theme',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (controller.name.value.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme name required')),
                );
                return;
              }
              await controller.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme saved and applied')),
                );
                Get.back();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final s = controller.settings.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Theme Name'),
              onChanged: (v) => controller.name.value = v,
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Seed Color'),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.seedColor,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () async {
                final color = await ColorPickerSheet.show(context, s.seedColor);
                if (color != null) controller.setSeedColor(color.toARGB32());
              },
            ),
            // Gün 12: anahtar başlıkları l10n'e taşındı (eskiden gömülü
            // İngilizceydi) ve her anahtar altyazı aldı.
            SettingsGroupCard(children: [
              SettingsSwitchTile(
                title: l10n.themeAmoledOn,
                subtitle: l10n.settingsAmoledDarkDescription,
                value: s.amoled,
                onChanged: controller.setAmoled,
              ),
              SettingsSwitchTile(
                title: l10n.themeHighContrast,
                subtitle: l10n.themeHighContrastDesc,
                value: s.highContrast,
                onChanged: controller.setHighContrast,
              ),
            ]),
          ],
        );
      }),
    );
  }
}
