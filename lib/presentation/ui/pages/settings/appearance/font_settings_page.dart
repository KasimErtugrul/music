import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/font_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

class FontSettingsPage extends StatelessWidget {
  const FontSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeFont)),
      body: Obx(() {
        final current = themeCtrl.settings.value.fontFamily;

        return ListView(
          children: FontRegistry.fonts.map((font) {
            //final isSelected = current == font.family;
            return RadioListTile<String>(
              title: Text(
                font.label,
                style: TextStyle(fontFamily: font.family),
              ),
              subtitle: Text(
                'ç ğ ı İ ö ş ü — 0123456789',
                style: TextStyle(fontFamily: font.family),
              ),
              value: font.family,
              groupValue: current,
              onChanged: (v) {
                if (v != null) themeCtrl.setFont(v);
              },
            );
          }).toList(),
        );
      }),
    );
  }
}