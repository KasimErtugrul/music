import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/theme/font_registry.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';

/// Yazı tipi ve yazı ölçeği ayarları.
///
/// Görev 1.6: Ölçek kaydırıcısı eklendi (0.80x–1.40x aralığı, 12 adım).
/// Gün 3: kalıcılık artık onChangeEnd'de yapılır — sürükleme sırasında
/// her kademde SharedPreferences'a yazılmaz (previewTextScale yalnız canlı
/// önizleme verir; commitTextScale bırakınca yazar). Ayrıca ölçek, uygulama
/// genelinde sistem ölçeğiyle ÇARPILARAK uygulanır (app.dart Gün 3).
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
        final scale = themeCtrl.settings.value.textScale;

        return ListView(
          children: [
            ...FontRegistry.fonts.map((font) {
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
            }),
            const Divider(height: 32),
            // --- Yazı ölçeği (Görev 1.6) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.themeTextScale,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${scale.toStringAsFixed(2)}x',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Slider(
              // Kayıtlı değer aralık dışıysa (eski sürüm verisi) korumalı oku;
              // kaydırıcı 0.80x–1.40x aralığında 0.05'lik adımlarla çalışır.
              value: scale.clamp(0.8, 1.4).toDouble(),
              min: 0.8,
              max: 1.4,
              divisions: 12,
              label: '${scale.toStringAsFixed(2)}x',
              // Gün 3: sürükleme sırasında yalnız önizleme (disk yazımı yok);
              // kalıcılık onChangeEnd'de tek seferde yapılır.
              onChanged: themeCtrl.previewTextScale,
              onChangeEnd: (_) => themeCtrl.commitTextScale(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }
}
