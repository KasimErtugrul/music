import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/home_widget_controller.dart';
import 'package:resonance/presentation/controllers/player_controller.dart';
import 'package:resonance/presentation/ui/widgets/artwork_image.dart';

/// Ana ekran widget'ı ayarları — M3 tasarım güncellemesi:
/// - Canlı önizleme: gerçek PlayerController durumunu (kapak, başlık,
///   sanatçı, çalma durumu) yansıtan 4x1 temsili kart; şeffaflık anahtarı
///   önizlemeye anında uygulanır ve gerçek widget'a yazılır
/// - Şeffaf arka plan: gerçek tercih (HomeWidgetController.setTransparency)
/// - Nasıl eklenir kartı + RemoteViews notu
///
/// Tasarımdaki 4x2 / 2x2 önizlemeleri, dinamik renk, opaklık kaydırıcısı,
/// köşe yuvarlaklığı ve dokunma davranışı seçici EKLENMEDİ: native tarafta
/// yalnızca tek widget sağlayıcısı (MusicWidgetProvider) ve şeffaflık
/// tercihi vardır; olmayan RemoteViews özellikleri vaat edilemez (README).
class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  late bool _transparent;

  @override
  void initState() {
    super.initState();
    // Gün 5: ham prefs erişimi ('widget_transparent' dizgesi) kaldırıldı;
    // başlangıç değeri HomeWidgetController.transparency'den okunur —
    // anahtara yalnız SettingsPersistence sabiti üzerinden dokunulur.
    _transparent = Get.find<HomeWidgetController>().transparency;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = Get.find<HomeWidgetController>();
    final player = Get.find<PlayerController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // --- Canlı önizleme bandı ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: cs.primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l10n.widgetPreviewLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.widgetSizeBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final song = player.currentSong;
                  final item = player.currentItem.value;
                  final playing = player.isPlaying.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _transparent
                          ? cs.surfaceContainerHigh.withValues(alpha: 0.55)
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: ArtworkImage(
                            songId: song?.id,
                            borderRadius: BorderRadius.circular(999),
                            fallbackIcon: Icons.music_note,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item?.title ?? l10n.playerNoSong,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item?.artist ?? l10n.unknownArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: FilledButton(
                            onPressed: player.togglePlayPause,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // --- Şeffaflık (gerçek tercih) ---
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.opacity, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.widgetTransparency,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.widgetTransparencyDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _transparent,
                  onChanged: (val) {
                    setState(() => _transparent = val);
                    ctrl.setTransparency(val);
                  },
                ),
              ],
            ),
          ),

          // --- Nasıl eklenir ---
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.widgets,
                      size: 20, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addWidgetHint,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.widgetNativeNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}