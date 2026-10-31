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
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_page_reset_action.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';
import 'package:resonance/presentation/ui/widgets/settings_switch_tile.dart';
import 'package:resonance/presentation/ui/widgets/theme_preview_card.dart';
import 'package:share_plus/share_plus.dart';

/// «Görünüm» — Gün 13'te Galeri ve Gelişmiş (tune) sayfalarının BİRLEŞTİRİLMİŞ
/// hâli (Karar: «Gelişmiş» sayfa Görünüm sayfasına birleşir). Tek sayfada
/// bölümler: sabit canlı önizleme (kaydırılmaz) → mod (+ zamanlanmış koyu)
/// → renk (kaynak, kontrast, yüzey tonu) → şekil ve yoğunluk → hazır
/// paletler → özel temalar.
///
/// Birleşmenin getirdiği tekilleştirmeler:
/// - Tema modu artık tek denetimdir: 4 seçenekli [SettingsChoiceTile]
///   (Sistem / Açık / Koyu / AMOLED). Eski Gelişmiş sayfasındaki ayrı AMOLED
///   anahtarı bu seçeneğe taşındı (AMOLED = koyu mod + saf siyah yüzey).
/// - Hazır palet seçimi yalnız görsel ızgaradadır; Gelişmiş sayfasındaki
///   metin seçicisi ızgaranın birebir yinelemesiydi, kaldırıldı.
/// - Yazı tipi/yazı ölçeği bu sayfada YOK: kendi sayfası (FontSettingsPage)
///   ve oynatıcı/liste stilleri ayrı sayfalardır; «Bu sayfayı varsayılana
///   döndür» bu yüzden yalnız buradaki alanları sıfırlar.
class ThemeGalleryPage extends StatelessWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();
    final customRepo = Get.find<CustomThemeRepository>();

    return Scaffold(
      // Gün 13: AppBar artık sayfanın adını gösterir (eski başlıklar
      // tabSettings / themeGroupColor idi; bilgi mimarisi kaynağı
      // settingsRowAppearance'dır — ana sayfadaki satırın aynı anahtarı).
      appBar: AppBar(
        title: Text(l10n.settingsRowAppearance),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.themeImportTheme,
            onPressed: () => _importTheme(context, themeCtrl),
          ),
          SettingsPageResetAction(onReset: () async {
            // Gün 13: yalnız BU sayfada yaşayan tema alanları fabrika
            // değerine döner; yazı tipi, yazı ölçeği, oynatıcı stili ve
            // liste görünümü kendi sayfalarında yaşadığı için korunur.
            final s = themeCtrl.settings.value;
            themeCtrl.setSettings(const ThemeSettings().copyWith(
              fontFamily: s.fontFamily,
              textScale: s.textScale,
              player: s.player,
              listViewMode: s.listViewMode,
            ));
          }),
        ],
      ),
      body: Obx(() {
        final s = themeCtrl.settings.value;

        // Gün 13: sabit canlı önizleme — kaydırılan listenin DIŞINDA,
        // her bölüm değişiminde anında güncellenen bir örnek kart.
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ThemePreviewCard(settings: s),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // --- Mod (+ zamanlanmış koyu mod) ---
                  SettingsSectionHeader(title: l10n.settingsThemeMode),
                  SettingsGroupCard(children: [
                    SettingsChoiceTile<String>(
                      title: l10n.settingsThemeMode,
                      subtitle: l10n.settingsThemeModeDesc,
                      value: _modeKey(s),
                      options: const <String>['system', 'light', 'dark', 'amoled'],
                      labelOf: (v) => switch (v) {
                        'light' => l10n.settingsThemeLight,
                        'dark' => l10n.settingsThemeDark,
                        'amoled' => l10n.themeModeAmoled,
                        _ => l10n.settingsThemeSystem,
                      },
                      onChanged: (key) => _applyMode(themeCtrl, key),
                    ),
                    // Gün 3 (Karar): zamanlanmış koyu mod varsayılan kapalıdır;
                    // yalnız mod Sistem iken anlamlıdır (eski Gelişmiş
                    // sayfasından taşındı).
                    if (s.themeMode == ThemeMode.system) ...[
                      SettingsSwitchTile(
                        title: l10n.themeScheduledDark,
                        subtitle: l10n.themeScheduledDarkDesc,
                        value: s.scheduledDarkEnabled,
                        onChanged: themeCtrl.setScheduledDarkEnabled,
                      ),
                      if (s.scheduledDarkEnabled)
                        ListTile(
                          title: Text(
                            '${s.scheduledDarkStartHour.toString().padLeft(2, '0')}:${s.scheduledDarkStartMinute.toString().padLeft(2, '0')}'
                            ' - '
                            '${s.scheduledDarkEndHour.toString().padLeft(2, '0')}:${s.scheduledDarkEndMinute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () async {
                            final start = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: s.scheduledDarkStartHour,
                                  minute: s.scheduledDarkStartMinute),
                            );
                            if (start == null) return;
                            if (!context.mounted) return;
                            final end = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: s.scheduledDarkEndHour,
                                  minute: s.scheduledDarkEndMinute),
                            );
                            if (end == null) return;

                            themeCtrl.setScheduledDark(
                              start.hour, start.minute,
                              end.hour, end.minute,
                            );
                          },
                        ),
                    ],
                  ]),

                  // --- Renk ---
                  SettingsSectionHeader(title: l10n.themeGroupColor),
                  SettingsGroupCard(children: [
                    SettingsChoiceTile<String>(
                      title: l10n.themeColorSource,
                      subtitle: l10n.themeColorSourceDesc,
                      value: s.themeSource,
                      options: const <String>['seed', 'system', 'artwork'],
                      labelOf: (v) => switch (v) {
                        'system' => l10n.themeSourceSystem,
                        'artwork' => l10n.themeSourceArtwork,
                        _ => l10n.themeSourceSeed,
                      },
                      onChanged: themeCtrl.setThemeSource,
                    ),
                    SettingsSwitchTile(
                      title: l10n.themeHighContrast,
                      subtitle: l10n.themeHighContrastDesc,
                      value: s.highContrast,
                      onChanged: themeCtrl.setHighContrast,
                    ),
                    SettingsSwitchTile(
                      title: l10n.themeSurfaceTint,
                      subtitle: l10n.themeSurfaceTintDesc,
                      value: s.surfaceTint,
                      onChanged: themeCtrl.setSurfaceTint,
                    ),
                  ]),

                  // --- Şekil ve yoğunluk ---
                  SettingsSectionHeader(title: l10n.themeGroupShape),
                  SettingsGroupCard(children: [
                    SettingsSwitchTile(
                      title: l10n.themeRoundedCorners,
                      subtitle: l10n.themeRoundedCornersDesc,
                      value: s.roundedCorners,
                      onChanged: themeCtrl.setRoundedCorners,
                    ),
                    SettingsChoiceTile<VisualDensity>(
                      title: l10n.themeDensity,
                      subtitle: l10n.themeDensityDesc,
                      value: s.density,
                      options: const <VisualDensity>[
                        VisualDensity.compact,
                        VisualDensity.standard,
                        VisualDensity.comfortable,
                      ],
                      labelOf: (d) => switch (d) {
                        VisualDensity.compact => l10n.themeDensityCompact,
                        VisualDensity.standard => l10n.themeDensityStandard,
                        _ => l10n.themeDensityComfortable,
                      },
                      onChanged: themeCtrl.setDensity,
                    ),
                  ]),

                  // --- Hazır paletler (görsel ızgara; seçim tohuma eşlenir) ---
                  SettingsSectionHeader(title: l10n.themePresetsTitle),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisExtent: 132,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: ThemePresets.all.length,
                    itemBuilder: (context, i) {
                      final preset = ThemePresets.all[i];
                      final isSelected = s.themeSource == 'seed' &&
                          s.seedColor == preset.seed;
                      return _PaletteCard(
                        name: preset.name,
                        seed: preset.seed,
                        isSelected: isSelected,
                        onTap: () {
                          // Kaynağı da tohuma çevir ki dokunuş anında
                          // etki etsin.
                          if (s.themeSource != 'seed') {
                            themeCtrl.setThemeSource('seed');
                          }
                          themeCtrl.setSeed(preset.seed);
                        },
                      );
                    },
                  ),

                  // --- Özel temalar (Drift tabanlı; düzenle/dışa aktar/sil) ---
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
                          onPressed: () =>
                              Get.to(() => const CustomThemeEditorPage()),
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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.themeCustomEmpty,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
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
                            // Gün 3 (Karar): özel tema yalnız renk/şekil
                            // alanlarıyla uygulanır
                            // (ThemeController.applyCustomTheme).
                            onTap: () =>
                                themeCtrl.applyCustomTheme(theme.settings),
                            onLongPress: () => _showThemeOptions(
                                context, theme, customRepo),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Mevcut ayarlardan segment anahtarı. AMOLED = koyu mod + saf siyah
  /// yüzey tercihi; dört durum tek seçim listesinde kalıcıdır.
  String _modeKey(ThemeSettings s) {
    if (s.themeMode == ThemeMode.light) return 'light';
    if (s.themeMode == ThemeMode.system) return 'system';
    return s.amoled ? 'amoled' : 'dark';
  }

  /// Seçimi gerçek modele çevirir. "Koyu" seçimi AMOLED'i kapatır;
  /// "AMOLED" seçimi koyu modu açar (birebir eski galeri davranışı,
  /// model bozulmadan).
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

  /// Gün 3: tema dışa aktarma .json DOSYASI olarak paylaşılır (mevcut
  /// path_provider + share_plus ile; yeni bağımlılık yok). Alıcı taraf
  /// dosyayı "Temayı içe aktar" ile açar.
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
