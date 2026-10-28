import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resonance/data/models/equalizer_model.dart';
import 'package:resonance/l10n/app_localizations.dart';
import 'package:resonance/presentation/controllers/equalizer_controller.dart';

/// UI tasarım güncellemesi: ekolayzır sayfası tasarım diline göre yeniden
/// düzenlendi — üstte ana anahtarlı kontrol kartı, hazır profillerin yatay
/// "pill" şeridi (dropdown yerine), donanım bantları kartı ve loudness
/// kartı (değer rozetli).
///
/// Tasarımdaki Bas Güçlendirme / Sanal Çevreleyen kartları bilinçli olarak
/// EKLENMEDİ: just_audio'ın Android eş katmanı yalnızca Equalizer +
/// LoudnessEnhancer sunar; BassBoost/Virtualizer API'leri uygulamanın
/// ses motorunda yoktur. Uydurma anahtar eklemek yerine gerçek kartlar
/// korunmuştur.
class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  /// Son uygulanan profilin kimliği ('builtin_flat' / 'custom_3').
  /// Bantlar elle değiştirilirse seçim vurgusu temizlenir.
  String? _activePreset;

  void _applyBuiltIn(EqualizerController ctrl, BuiltInPreset p) {
    ctrl.applyBuiltInPreset(p);
    setState(() => _activePreset = 'builtin_${p.id}');
  }

  Future<void> _reset(EqualizerController ctrl) async {
    final flat =
        ctrl.builtInPresets.firstWhere((p) => p.id == 'flat');
    await ctrl.applyBuiltInPreset(flat);
    setState(() => _activePreset = 'builtin_flat');
  }

  Future<void> _deleteCustom(
    BuildContext context,
    EqualizerController ctrl,
    EqualizerPresetModel preset,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text('"${preset.name}" — ${l10n.commonDelete}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ctrl.deletePreset(preset.id);
      if (mounted && _activePreset == 'custom_${preset.id}') {
        setState(() => _activePreset = null);
      }
    }
  }

  Future<void> _showSaveDialog(
    BuildContext context,
    EqualizerController ctrl,
    AppLocalizations l10n,
  ) async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.equalizerSavePreset),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: l10n.equalizerPresetName),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ctrl.savePreset(name);
    }
  }

  String _freqLabel(double hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)} kHz';
    return '${hz.round()} Hz';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctrl = Get.find<EqualizerController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.equalizerTitle)),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.bands.isEmpty) {
          return Center(child: Text(l10n.equalizerNoBands));
        }

        final enabled = ctrl.isEnabled.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Kontrol kartı: ikon + başlık + ana anahtar ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.graphic_eq,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.equalizerTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${ctrl.bands.length} ${l10n.eqBandsUnit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ctrl.isEnabled.value,
                      onChanged: ctrl.toggleEnabled,
                    ),
                  ],
                ),
              ),

              // --- Hazır profiller: yatay pill şeridi ---
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.equalizerPresets,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.restart_alt),
                      tooltip: l10n.eqReset,
                      onPressed: enabled ? () => _reset(ctrl) : null,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      tooltip: l10n.equalizerSavePreset,
                      onPressed: enabled
                          ? () => _showSaveDialog(context, ctrl, l10n)
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final p in ctrl.builtInPresets)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PresetPill(
                          label: _builtInLabel(l10n, p.id),
                          active: _activePreset == 'builtin_${p.id}',
                          onTap: enabled ? () => _applyBuiltIn(ctrl, p) : null,
                        ),
                      ),
                    for (final p in ctrl.presets)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PresetPill(
                          label: p.name,
                          active: _activePreset == 'custom_${p.id}',
                          onTap: enabled
                              ? () {
                                  ctrl.applyPreset(p);
                                  setState(
                                      () => _activePreset = 'custom_${p.id}');
                                }
                              : null,
                          onLongPress: enabled
                              ? () =>
                                    _deleteCustom(context, ctrl, p, l10n)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),

              // --- Donanım bantları kartı ---
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.tune,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(l10n.eqBandsTitle, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 280,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: ctrl.bands.asMap().entries.map((entry) {
                      final index = entry.key;
                      final band = entry.value;
                      final gain = band.gain.clamp(
                          ctrl.minDecibels, ctrl.maxDecibels);
                      final touched = gain.abs() > 0.05;
                      return Column(
                        children: [
                          Text(
                            gain.toStringAsFixed(1),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: touched
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  value: gain,
                                  min: ctrl.minDecibels,
                                  max: ctrl.maxDecibels,
                                  onChanged: enabled
                                      ? (v) {
                                          ctrl.updateBand(index, v);
                                          if (_activePreset != null) {
                                            setState(
                                                () => _activePreset = null);
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _freqLabel(band.centerFrequency.toDouble()),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              // --- Loudness kartı (değer rozetli) ---
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.volume_up,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.loudnessEnhancer,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        // Görev 2.3 birim düzeltmesi: değer dB cinsindedir.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${ctrl.loudnessGain.value.toStringAsFixed(1)} dB',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      // Görev 2.3 birim düzeltmesi: değer artık doğrudan
                      // dB cinsindendir (0-15 dB). Eski kod kaydırıcıyı
                      // mB varsayıp /100 ile gösteriyordu; oysa
                      // just_audio Dart tarafında dB bekliyor, Android'e
                      // Java katmanı x100 ile milibele çeviriyor.
                      value: ctrl.loudnessGain.value.clamp(0.0, 15.0),
                      min: 0,
                      max: 15,
                      divisions: 30,
                      label:
                          '${ctrl.loudnessGain.value.toStringAsFixed(1)} dB',
                      onChanged:
                          enabled ? (v) => ctrl.setLoudness(v) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _builtInLabel(AppLocalizations l10n, String id) => switch (id) {
        'flat' => l10n.eqPresetFlat,
        'rock' => l10n.eqPresetRock,
        'pop' => l10n.eqPresetPop,
        'jazz' => l10n.eqPresetJazz,
        'classical' => l10n.eqPresetClassical,
        'bass' => l10n.eqPresetBass,
        'treble' => l10n.eqPresetTreble,
        'vocal' => l10n.eqPresetVocal,
        _ => id,
      };
}

/// Hazır profil "pill"i: seçiliyken secondary-container dolgulu.
class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.active,
    this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: active ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
