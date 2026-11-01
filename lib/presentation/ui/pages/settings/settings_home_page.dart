import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/core/routes/app_routes.dart';
import 'package:resonance/core/settings/settings_registry.dart';
import 'package:resonance/core/utils/responsive.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';
import 'package:resonance/presentation/controllers/library_controller.dart';
import 'package:resonance/presentation/controllers/preferences_controller.dart';
import 'package:resonance/presentation/controllers/settings_controller.dart';
import 'package:resonance/presentation/controllers/settings_search_controller.dart';
import 'package:resonance/presentation/ui/pages/settings/about_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/font_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/list_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/player_style_page.dart';
import 'package:resonance/presentation/ui/pages/settings/appearance/theme_gallery_page.dart';
import 'package:resonance/presentation/ui/pages/backup_page.dart';
import 'package:resonance/presentation/ui/pages/settings/audio_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/library_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/playback_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/tags_artwork_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/notifications/notification_settings_page.dart';
import 'package:resonance/presentation/ui/pages/settings/widget_settings_page.dart';
import 'package:resonance/presentation/ui/widgets/empty_state.dart';
import 'package:resonance/presentation/ui/widgets/settings_choice_tile.dart';
import 'package:resonance/presentation/ui/widgets/settings_group_card.dart';
import 'package:resonance/presentation/ui/widgets/settings_page_reset_action.dart';
import 'package:resonance/presentation/ui/widgets/settings_section_header.dart';

/// UI tasarım güncellemesi: Ayarlar ana sayfası artık tasarım dilini izler —
/// yuvarlak arama çubuğu gövdede, ikonlu+kategorik grup kartları ve altta
/// gerçek veriden beslenen bir durum kartı.
///
/// Arama davranışı Görev 4.2'den aynen korunur: sorgu boş değilken eşleşme
/// tüm [SettingsRegistry] girdileri üzerinde yapılır (iki dilli) ve sonuç,
/// hedef sayfaya giden satırlar olarak basılır (pageBuilder + Get.to).
///
/// Gün 12: grup kartları ortak [SettingsGroupCard] bileşenine devredildi
/// (eski özel _NavCard silindi); Dil anahtarı l10n alt açıklama aldı ve
/// SettingsChoiceTile artık SegmentedButton çiziyor.
///
/// Gün 14: geniş ekranda (ayalar alanı >= 840 dp — M3 expanded, mevcut
/// [Responsive] yardımcısı) iki bölmeli ayarlar: solda liste, sağda seçilen
/// ayrıntı sayfası. Compact yerleşim ve davranış birebir korunur; ayar
/// alanının KENDİ genişliği ölçülür (LayoutBuilder) — rail/panel alanları
/// düşüldükten sonraki gerçek yerleşim alanı baz alınır.
class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key});

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  final _searchController = TextEditingController();

  /// Gün 14: geniş ekranda sağ bölmede açık olan hedef (null = yer tutucu).
  /// Rxn: liste satırlarındaki seçim vurgusu da bu değeri okuduğu için
  /// değişimde her iki bölme de Obx ile kendiliğinden yeniden çizilir.
  final _selected = Rxn<_PaneTarget>();

  /// Son build'de hesaplanan iki bölme modu; tap geri çağrılarında kullanılır
  /// (build bağlamı dışında MediaQuery/LayoutBuilder okunamaz).
  bool _twoPane = false;

  /// Sol bölme sabit genişlik: 840 dp'de ayrıntıya 840-340-1 ≈ 500 dp kalır.
  static const double _listPaneWidth = 340;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Gün 14: satır dokunuşu — geniş ekranda sağ bölmeyi değiştirir,
  /// compact'ta eskisi gibi sayfayı route olarak açar.
  void _open(_PaneTarget target) {
    if (_twoPane) {
      _selected.value = target;
    } else {
      Get.to(target.builder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctrl = Get.find<SettingsController>();
    final search = Get.put(SettingsSearchController());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Gün 14: eşik, ayar alanının kendi genişliğinde M3 expanded
          // kırılımıdır (840 dp). 800x600'lük varsayılan test yüzeyi ve
          // orta boy telefonlar compact'ta kalır — mevcut davranış korunur.
          _twoPane = Responsive.fromWidth(constraints.maxWidth) ==
              WindowSize.expanded;
          final listPane = _buildListPane(l10n, theme, ctrl, search);
          if (!_twoPane) return listPane;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: _listPaneWidth, child: listPane),
              const VerticalDivider(width: 1),
              Expanded(child: _buildDetailPane(l10n)),
            ],
          );
        },
      ),
    );
  }

  /// Gün 14: sağ bölme — seçim yoksa yer tutucu; seçili hedef sayfası
  /// kendi Scaffold/AppBar'ıyla bölme içinde çizilir (iç sayfaların Get.to
  /// ile açtığı alt sayfalar — özel tema düzenleyici, ekolayzer vb. —
  /// tam ekran route olarak açılmaya devam eder).
  Widget _buildDetailPane(AppLocalizations l10n) {
    return Obx(() {
      final target = _selected.value;
      if (target == null) {
        return EmptyState(
          icon: Icons.tune,
          title: l10n.settingsPickPrompt,
        );
      }
      return KeyedSubtree(
        key: ValueKey<String>(target.id),
        child: target.builder(),
      );
    });
  }

  Widget _buildListPane(
    AppLocalizations l10n,
    ThemeData theme,
    SettingsController ctrl,
    SettingsSearchController search,
  ) {
    return Column(
        children: [
          // --- M3 arama çubuğu (tasarım: yuvarlak, dolgulu) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => search.query.value = v,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.settingsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: l10n.commonClear,
                          onPressed: () {
                            _searchController.clear();
                            search.query.value = '';
                          },
                        ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHigh,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final settings = ctrl.settings.value;
              if (settings == null) return const Center(child: Text('—'));

              // Görev 4.2: arama boş değilse registry üzerinden iki dilli
              // eşleme; sonuç satırı hedef sayfayı builder ile açar.
              if (search.query.value.trim().isNotEmpty) {
                final results = search.filter(SettingsRegistry.all, l10n);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: <Widget>[
                    for (final e in results)
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(e.title(l10n)),
                        trailing: e.pageBuilder != null
                            ? const Icon(Icons.chevron_right)
                            : null,
                        onTap: e.pageBuilder == null
                            ? null
                            : () => _open(
                                  _PaneTarget(
                                    id: e.key,
                                    builder: e.pageBuilder!,
                                  ),
                                ),
                      ),
                  ],
                );
              }

              final general = search.filter(
                SettingsRegistry.byGroup(SettingsGroup.general),
                l10n,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  if (general.isNotEmpty) ...<Widget>[
                    SettingsSectionHeader(title: l10n.settingsGroupGeneral),
                    SettingsGroupCard(children: [
                      ...general.map((e) => _entry(e, l10n, ctrl)),
                    ]),
                  ],

                  // --- Genel & motor ---
                  SettingsGroupCard(children: [
                    _NavRow(
                      icon: Icons.play_circle_outline,
                      title: l10n.settingsPlayback,
                      desc: l10n.settingsDescPlayback,
                      selected: _selected.value?.id == 'nav_playback',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_playback',
                        builder: () => const PlaybackSettingsPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.equalizer,
                      title: l10n.audioSettingsTitle,
                      desc: l10n.settingsDescAudio,
                      selected: _selected.value?.id == 'nav_audio',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_audio',
                        builder: () => const AudioSettingsPage(),
                      )),
                    ),
                  ]),

                  // --- Kütüphane ve içerik ---
                  SettingsSectionHeader(title: l10n.settingsGroupContent),
                  SettingsGroupCard(children: [
                    _NavRow(
                      icon: Icons.folder_special,
                      title: l10n.settingsLibrary,
                      desc: l10n.settingsDescLibrary,
                      selected: _selected.value?.id == 'nav_library',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_library',
                        builder: () => const LibrarySettingsPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.image_outlined,
                      title: l10n.tagsArtworkSettings,
                      desc: l10n.settingsDescTags,
                      selected: _selected.value?.id == 'nav_tags',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_tags',
                        builder: () => const TagsArtworkSettingsPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.widgets_outlined,
                      title: l10n.widgetSettings,
                      desc: l10n.settingsDescWidget,
                      selected: _selected.value?.id == 'nav_widget',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_widget',
                        builder: () => const WidgetSettingsPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.notifications_outlined,
                      title: l10n.settingsRowNotifications,
                      desc: l10n.settingsDescNotifications,
                      selected: _selected.value?.id == 'nav_notifications',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_notifications',
                        builder: () => const NotificationSettingsPage(),
                      )),
                    ),
                    // Gün 17 (Kasa): iki bölmeye gömülmez, tam ekran rota.
                    // Hassas içerik yalnız kendi ekranında gösterilir.
                    _NavRow(
                      icon: Icons.lock_outline,
                      title: l10n.vaultTitle,
                      desc: l10n.settingsDescVault,
                      onTap: () => Get.toNamed(AppRoutes.vault),
                    ),
                  ]),

                  // --- Görünüm ---
                  SettingsSectionHeader(title: l10n.settingsGroupAppearance),
                  SettingsGroupCard(children: [
                    _NavRow(
                      icon: Icons.palette_outlined,
                      title: l10n.settingsRowAppearance,
                      desc: l10n.settingsDescTheme,
                      selected: _selected.value?.id == 'nav_appearance',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_appearance',
                        builder: () => const ThemeGalleryPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.text_fields,
                      title: l10n.themeFont,
                      desc: l10n.settingsDescFont,
                      selected: _selected.value?.id == 'nav_font',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_font',
                        builder: () => const FontSettingsPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.music_note,
                      title: l10n.themePlayerTitle,
                      desc: l10n.settingsDescPlayerStyle,
                      selected: _selected.value?.id == 'nav_player_style',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_player_style',
                        builder: () => const PlayerStylePage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.list_alt,
                      title: l10n.themeListTitle,
                      desc: l10n.settingsDescListStyle,
                      selected: _selected.value?.id == 'nav_list_style',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_list_style',
                        builder: () => const ListStylePage(),
                      )),
                    ),
                  ]),

                  // --- Sistem ---
                  SettingsSectionHeader(title: l10n.settingsGroupSystem),
                  SettingsGroupCard(children: [
                    _NavRow(
                      icon: Icons.backup,
                      title: l10n.backupTitle,
                      desc: l10n.settingsDescBackup,
                      selected: _selected.value?.id == 'nav_backup',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_backup',
                        builder: () => const BackupPage(),
                      )),
                    ),
                    _NavRow(
                      icon: Icons.info_outline,
                      title: l10n.settingsAbout,
                      desc: l10n.settingsDescAbout,
                      selected: _selected.value?.id == 'nav_about',
                      onTap: () => _open(_PaneTarget(
                        id: 'nav_about',
                        builder: () => const AboutPage(),
                      )),
                    ),
                  ]),

                  // --- Gün 6: Tüm ayarları sıfırla ---
                  // Yıkıcı eylem en sonda, kendi kartında. Taban l10n
                  // dizgeleri (resetAll / resetConfirm) Gün 6 ile ilk kez
                  // gerçek bir ekrana bağlandı.
                  SettingsGroupCard(children: [
                    _NavRow(
                      icon: Icons.restart_alt,
                      title: l10n.resetAll,
                      desc: l10n.resetAllDesc,
                      onTap: () => _confirmReset(context),
                    ),
                  ]),

                  // --- Alt durum kartı (gerçek veri) ---
                  const SizedBox(height: 16),
                  const _EngineStatusCard(),
                ],
              );
            }),
          ),
        ],
      );
  }

  Widget _entry(
    SettingsEntry e,
    AppLocalizations l10n,
    SettingsController ctrl,
  ) {
    switch (e.key) {
      case 'language_code':
        return SettingsChoiceTile<String>(
          title: l10n.settingsLanguage,
          subtitle: l10n.settingsLanguageDesc,
          value: ctrl.settings.value!.languageCode,
          options: const <String>['system', 'tr', 'en'],
          labelOf: (v) => switch (v) {
            'tr' => 'Türkçe',
            'en' => 'English',
            _ => l10n.settingsLanguageSystem,
          },
          onChanged: ctrl.setLanguage,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Gün 6: sıfırlama onayı. Onaylanırsa diskteki tüm yedeklenen ayar
  /// anahtarları kaldırılır ve canlı controller'lar yeniden yüklenir
  /// (PreferencesController.resetAll); sonuç SnackBar ile bildirilir.
  ///
  /// Gün 15: diyaloğun birebir kopyası SettingsPageResetAction.confirmAndRun
  /// statik yardımcısına taşındı (Gün 13'teki sayfa eylemiyle aynı desen);
  /// burada yalnız «Tümünü sıfırla» dizgeleriyle çağrılır. Görsel akış ve
  /// disk etkisi birebir korunur (Gün 6 widget testi bu sözleşmeyi taşır).
  Future<void> _confirmReset(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPageResetAction.confirmAndRun(
      context,
      title: l10n.resetAll,
      content: l10n.resetConfirm,
      confirmLabel: l10n.resetAll,
      onReset: () => Get.find<PreferencesController>().resetAll(),
    );
  }
}

/// Kategori satırı: ikon rozeti + başlık + açıklama + chevron.
/// (Gün 12: grup yüzeyi ortak SettingsGroupCard'a devredildi.)
/// Gün 14: [selected] — geniş ekranda sağ bölmede açık sayfanın satırı
/// secondaryContainer zeminle vurgulanır. Zemin Ink ile MALZEMEYE
/// çizilir: InkWell mürekkebi (Gün 13 düzeltmesi) hâlâ üstünde görünür.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Ink(
        color: selected
            ? cs.secondaryContainer.withValues(alpha: 0.45)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
        ),
      ),
    );
  }
}

/// Alt durum kartı. Tasarımdaki "ses motoru" rozetinin dürüst karşılığı:
/// uydurma bit-perfect bilgisi yerine kitaplık parça sayısı ve ekolayzır
/// durumu gösterilir (ikisi de gerçek, canlı veridir).
class _EngineStatusCard extends StatelessWidget {
  const _EngineStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasLibrary = Get.isRegistered<LibraryController>();
    final hasEq = Get.isRegistered<EqualizerController>();
    if (!hasLibrary && !hasEq) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusText(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          if (hasEq)
            Obx(() {
              final eq = Get.find<EqualizerController>();
              final on = eq.isEnabled.value;
              return Text(
                on
                    ? AppLocalizations.of(context).settingsStatusEqOn
                    : AppLocalizations.of(context).settingsStatusEqOff,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: on ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (Get.isRegistered<LibraryController>()) {
      final lib = Get.find<LibraryController>();
      final n = lib.songs.length;
      return '${l10n.settingsLibrary}: $n ${l10n.settingsStatusSongs}';
    }
    return l10n.settingsGroupGeneral;
  }
}

/// Gün 14: iki bölmeli yerleşimde sağ bölmeye konacak hedef. [id] hem
/// ValueKey hem seçim vurgusu karşılaştırmasıdır (nav_… önekli sabit kimlik
/// veya arama sonucunda registry anahtarı); [builder], registry'nin
/// pageBuilder'ıyla aynı tiptedir (Widget Function()) — compact modda
/// Get.to'nun, geniş ekranda KeyedSubtree çocuğunun doğrudan girdisidir.
@immutable
class _PaneTarget {
  const _PaneTarget({required this.id, required this.builder});

  final String id;
  final Widget Function() builder;
}

