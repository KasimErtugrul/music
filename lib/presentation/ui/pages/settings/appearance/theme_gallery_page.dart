import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resonance/core/theme/theme_engine.dart';
import 'package:resonance/core/theme/theme_presets.dart';
import 'package:resonance/data/models/custom_theme_model.dart';
import 'package:resonance/data/repositories/custom_theme_repository.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/theme_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/custom_theme_editor_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_settings_page.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/theme_preview_card.dart';
import 'package:share_plus/share_plus.dart';

/// UI tasarım güncellemesi: "Görünüm ve Tema Stüdyosu".
///
/// Tek ekranda sıralı bölümler: canlı önizleme → tema modu (Sistem / Açık /
/// Koyu / AMOLED) → renk kaynağı (Özel tohum / Material You / Kapaktan) →
/// hazır paletler (renk noktalı kartlar) → özel temalar (Drift tabanlı,
/// düzenle / dışa aktar / sil).
///
/// Tasarımdaki "WCAG AA/AAA kontrast kademesi" ve "3 kademeli köşe" kontrolleri
/// bilinçli olarak buraya taşınmadı: uygulamanın gerçek modelleri tek kademe
/// [ThemeSettings.highContrast] ve [ThemeSettings.roundedCorners] anahtarları
///dır; bunlar Gelişmiş tema ayarları sayfasında (tune) yaşamaya devam eder.
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
            tooltip: l10n.themeAdvancedSettings,
            onPressed: () => Get.to(() => const ThemeSettingsPage()),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.themeImportTheme,
            onPressed: () => _importTheme(context, themeCtrl),
          ),
        ],
      ),
      body: Obx(() {
        final s = themeCtrl.settings.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // --- 1. Canlı önizleme ---
            SettingsSectionHeader(title: l10n.themePreviewTitle),
            ThemePreviewCard(settings: s),

            // --- 2. Tema modu: 4 segment ---
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SettingsSectionHeader(title: l10n.settingsThemeMode),
            ),
            _SegmentedRow(
              selected: _modeKey(s),
              items: <String, String>{
                'system': l10n.settingsThemeSystem,
                'light': l10n.settingsThemeLight,
                'dark': l10n.settingsThemeDark,
                'amoled': 'AMOLED',
              },
              onSelect: (key) => _applyMode(themeCtrl, key),
            ),

            // --- 3. Renk kaynağı ---
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SettingsSectionHeader(title: l10n.themeColorSource),
            ),
            _SegmentedRow(
              selected: s.themeSource,
              items: <String, String>{
                'seed': l10n.themeSourceSeed,
                'system': l10n.themeSourceSystem,
                'artwork': l10n.themeSourceArtwork,
              },
              onSelect: themeCtrl.setThemeSource,
            ),

            // --- 4. Hazır paletler ---
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.themePresetsTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${ThemePresets.all.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 132,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: ThemePresets.all.length,
              itemBuilder: (context, i) {
                final preset = ThemePresets.all[i];
                final isSelected =
                    s.themeSource == 'seed' && s.seedColor == preset.seed;
                return _PaletteCard(
                  name: preset.name,
                  seed: preset.seed,
                  isSelected: isSelected,
                  onTap: () {
                    // Kaynağı da tohuma çevir ki dokunuş anında etki etsin.
                    if (s.themeSource != 'seed') {
                      themeCtrl.setThemeSource('seed');
                    }
                    themeCtrl.setSeed(preset.seed);
                  },
                );
              },
            ),

            // --- 5. Özel temalar ---
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.themeCustomTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: l10n.commonSave,
                    onPressed: () => Get.to(() => const CustomThemeEditorPage()),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<CustomThemeModel>>(
              stream: customRepo.watchAll(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l10n.themeCustomEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) {
                    final theme = snapshot.data![i];
                    return _PaletteCard(
                      name: theme.name,
                      seed: theme.settings.seedColor,
                      isSelected: false,
                      // Gün 3 (Karar): özel tema yalnız renk/şekil alanlarıyla
                      // uygulanır (ThemeController.applyCustomTheme).
                      onTap: () => themeCtrl.applyCustomTheme(theme.settings),
                      onLongPress: () =>
                          _showThemeOptions(context, theme, customRepo),
                    );
                  },
                );
              },
            ),
          ],
        );
      }),
    );
  }

  /// Mevcut ayarlardan segment anahtarı.
  String _modeKey(ThemeSettings s) {
    if (s.themeMode == ThemeMode.light) return 'light';
    if (s.themeMode == ThemeMode.system) return 'system';
    return s.amoled ? 'amoled' : 'dark';
  }

  /// Segment seçimini gerçek modele çevirir. AMOLED = koyu mod + saf siyah
  /// yüzey tercihi; "Koyu" seçimi AMOLED'i kapatır (birebir tasarım
  /// davranışı, model bozulmadan).
  void _applyMode(ThemeController ctrl, String key) => switch (key) {
        'light' => ctrl.setMode(ThemeMode.light),
        'dark' => () {
            ctrl.setAmoled(false);
            ctrl.setMode(ThemeMode.dark);
          }(),
        'amoled' => () {
            ctrl.setAmoled(true);
            ctrl.setMode(ThemeMode.dark);
          }(),
        _ => ctrl.setMode(ThemeMode.system),
      };

  void _showThemeOptions(
    BuildContext context,
    CustomThemeModel theme,
    CustomThemeRepository repo,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.commonEdit),
              onTap: () {
                Navigator.pop(sheetCtx);
                Get.to(() => CustomThemeEditorPage(existingTheme: theme));
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.commonExport),
              onTap: () {
                Navigator.pop(sheetCtx);
                _exportTheme(context, theme);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                l10n.commonDelete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await repo.deleteTheme(theme.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Gün 3: tema dışa aktarma artık düz metin değil, geçici dizine yazılan
  /// .json DOSYASI olarak paylaşılır (mevcut path_provider + share_plus ile;
  /// yeni bağımlılık yok). Alıcı taraf dosyayı "Tema içe aktar" ile açar.
  Future<void> _exportTheme(
    BuildContext context,
    CustomThemeModel theme,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final safeName = theme.name
          .replaceAll(RegExp(r'[^\w\- ]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${safeName.isEmpty ? 'tema' : safeName}.json';
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(theme.settings.toJson()),
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: theme.name),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.themeExportFailed)),
        );
      }
    }
  }

  Future<void> _importTheme(
    BuildContext context,
    ThemeController themeCtrl,
  ) async {
    final l10n = AppLocalizations.of(context);
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
      // Gün 3 (Karar): içe aktarılan tema da yalnız renk/şekil alanlarıyla
      // uygulanır; kullanıcının mod/yazı tipi/liste tercihleri korunur.
      themeCtrl.applyCustomTheme(settings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.themeImported)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.themeImportInvalid)),
        );
      }
    }
  }
}

/// Tek seçimli pill sırası: tema modu ve renk kaynağı için ortak bileşen
/// (tasarımdaki segmented button görünümü, M3 yüzey renkleriyle).
class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.selected,
    required this.items,
    required this.onSelect,
  });

  final String selected;
  final Map<String, String> items;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: Material(
                color: selected == entry.key
                    ? cs.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelect(entry.key),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected == entry.key
                              ? cs.onSecondaryContainer
                              : cs.onSurfaceVariant,
                          fontWeight:
                              selected == entry.key ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Palet kartı: isim + M3 türetilmiş 4 renk noktası + seçim rozeti.
/// Renk noktaları uydurma değil: her paletin tohumundan gerçek
/// [ColorScheme.fromSeed] ile üretilir (tasarımdaki 4 noktalı gösterimin
/// birebir karşılığı).
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.name,
    required this.seed,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final Color seed;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: theme.brightness,
    );
    final dots = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
    ];

    return Material(
      color: isSelected ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final c in dots) ...[
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check,
                      size: 14, color: cs.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
